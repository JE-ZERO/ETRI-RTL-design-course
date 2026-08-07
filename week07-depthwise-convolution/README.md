# MobileNetV2 Layer 8 Depthwise Convolution

MobileNetV2 Layer 8의 `384 × 14 × 14` feature map에 채널별 3×3 depthwise convolution을 수행하는 SystemVerilog RTL입니다. 한 출력에 필요한 곱셈 9개를 DSP48E2 9개로 병렬 처리하고 `PCOUT -> PCIN` cascade로 합산합니다.

## 포함 파일

실제 RTL 구성에 필요한 파일만 남겼습니다.

```text
week07-depthwise-convolution/
├─ README.md
├─ coe/
│  ├─ input_bram_easy.coe
│  └─ weight_rom_easy.coe
└─ depthwise.srcs/
   ├─ constrs_1/new/100MHz.xdc
   └─ sources_1/
      ├─ new/DWC_baseline.sv
      └─ ip/
         ├─ blk_mem_gen_2/blk_mem_gen_2.xci
         ├─ blk_mem_gen_3/blk_mem_gen_3.xci
         ├─ dsp_macro_0/dsp_macro_0.xci
         └─ dsp_macro_1/dsp_macro_1.xci
```

Vivado 프로젝트 파일, 테스트벤치, 로그, 캐시, IP output products, 합성·구현 결과와 현재 RTL이 인스턴스하지 않는 예전 IP는 제외했습니다. 두 COE는 BRAM XCI가 직접 참조하는 초기화 파일이므로 포함했습니다.

## 설계 사양

| 항목 | 값 |
| --- | ---: |
| 입력/출력 feature map | 384 × 14 × 14, CHW |
| kernel / stride / padding | 3×3 / 1 / 1 |
| 전체 출력 수 | 75,264 |
| 입력과 가중치 | signed 16-bit |
| DSP 누산 | signed 48-bit |
| DSP 수 | 9 |
| 기준 클럭 | 100 MHz |
| 대상 FPGA | `xczu3eg-sbva484-1-e` |
| 개발 도구 | Xilinx Vivado 2020.2 |

## 전체 데이터 흐름

```text
Input BRAM -> padding 선택 -> 2-line buffer -> 3×3 window -- A
Weight ROM -> 채널별 weight_data[0:8] -------------------- B
                                                          |
                                                   9-DSP cascade
                                                          |
                                                   48-bit dsp_sum
                                                          |
                                             result + result_valid + done
```

`start`는 한 클럭 pulse이며 `active`가 전체 연산 상태를 유지합니다. `channel`, `row`, `col`로 입력 주소와 padding 위치를 만들고, BRAM의 2클럭 read latency에 맞춰 좌표와 valid를 함께 지연합니다. 지연 좌표 자체는 reset하지 않으며, reset되는 valid가 0일 때는 사용하지 않습니다.

## 주소와 zero padding

입력과 weight는 channel-major 순서입니다.

```text
input_addr  = channel * 196 + row * 14 + col
weight_addr = channel * 9   + weight_index
```

`row`와 `col`은 0~14의 15×15 좌표를 스캔합니다. 16×16 padding 배열을 별도로 저장하지 않고 다음처럼 네 방향의 0을 만듭니다.

- 위쪽: 초기 두 행을 선택할 수 없을 때 `current`에 0을 넣습니다.
- 왼쪽: 매 행 시작 전에 `shift`를 0으로 비웁니다.
- 아래쪽: `row==14`인 추가 좌표에서 현재 입력을 0으로 선택합니다.
- 오른쪽: `col==14`인 추가 좌표에서 현재 열 전체를 0으로 선택합니다.

padding 좌표에서는 BRAM 범위를 벗어나지 않도록 현재 채널의 첫 주소를 유지하지만, 실제 window에는 BRAM 출력 대신 0이 들어갑니다.

## Line buffer와 3×3 window

| 신호 | 역할 |
| --- | --- |
| `line[0:1][0:13]` | 같은 열의 이전 두 실제 입력 행을 저장하는 2-line buffer |
| `current[0:2]` | 현재 열의 위·가운데·아래 픽셀 |
| `shift[0:2][0:1]` | 세 행에서 각각 왼쪽 두 픽셀을 기억하는 shift register |
| `window_data[0:8]` | `shift`의 두 열과 `current`의 한 열을 합친 3×3 window |

`current`와 `window_data`는 조합 신호이고 DSP 입력 레지스터가 clock edge에서 값을 받습니다. `window_valid`가 1인 window만 연산 결과로 사용합니다.

## DSP IP 구성과 결과 timing

| IP | 설정 | 용도 |
| --- | --- | --- |
| `dsp_macro_1` | signed 16×16, `A*B`, PCOUT 사용, PCIN 없음 | cascade 첫 DSP |
| `dsp_macro_0` | signed 16×16, `A*B+PCIN`, PCIN/PCOUT 사용 | 나머지 8개 DSP |

두 IP 모두 A/B 입력 레지스터 2단과 MREG 1단을 사용하고 PREG는 사용하지 않습니다. 첫 DSP를 PCIN 없는 별도 IP로 구성해, 연결되지 않은 PCIN을 사용하는 경우 발생하는 `DSPS-2`와 `AVAL-321` DRC를 피합니다.

DSP 내부 3클럭 뒤 조합 cascade 결과가 나오고 RTL의 `dsp_sum` 레지스터가 한 번 더 저장하므로 전체 결과 latency는 4클럭입니다. `result_valid_pipe`와 `done_pipe`도 같은 4클럭을 이동하며, 외부 로직은 각 pipe 전체가 아니라 MSB인 `result_valid`와 `done`을 사용합니다.

현재 `result[15:0]`은 48비트 `dsp_sum[47:32]`을 내보냅니다. 다음 계층과 연결할 때는 고정소수점 재양자화, 반올림과 포화 규칙에 맞춰 이 부분을 확정해야 합니다.

## Vivado에 추가하는 방법

1. Ultra96-V2용 프로젝트를 만들고 part를 `xczu3eg-sbva484-1-e`로 설정합니다.
2. `DWC_baseline.sv`를 Design Sources에 추가합니다.
3. 네 개의 XCI를 모두 Design Sources에 추가하고 IP output products를 생성합니다.
4. `100MHz.xdc`를 Constraints에 추가합니다.
5. design top을 `DWC_baseline`으로 설정합니다.

디렉터리 구조를 그대로 유지하면 BRAM XCI의 상대 경로가 `coe/input_bram_easy.coe`와 `coe/weight_rom_easy.coe`를 가리킵니다. 다른 초기화 데이터를 사용할 때는 Block Memory Generator에서 COE를 다시 선택한 뒤 output products를 재생성해야 합니다.
