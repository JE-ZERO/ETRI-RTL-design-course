# MobileNetV2 Layer 8 Depthwise Convolution

MobileNetV2 Layer 8의 `384 × 14 × 14` feature map에 채널별 3×3 depthwise convolution을 수행하는 SystemVerilog RTL입니다. 한 출력에 필요한 곱셈 9개를 DSP48E2 9개로 병렬 처리합니다. 단일 9-DSP cascade인 baseline과, 이를 3개씩 나누어 pipeline한 developed 설계를 함께 제공합니다.

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
   ├─ sim_1/new/tb_DWC_compare.sv
   └─ sources_1/
      ├─ new/
      │  ├─ DWC_baseline.sv
      │  └─ DWC_developed.sv
      └─ ip/
         ├─ blk_mem_gen_2/blk_mem_gen_2.xci
         ├─ blk_mem_gen_3/blk_mem_gen_3.xci
         ├─ dsp_macro_0/dsp_macro_0.xci
         └─ dsp_macro_1/dsp_macro_1.xci
```

Vivado 프로젝트 파일, 로그, 캐시, IP output products, 합성·구현 결과와 현재 RTL이 인스턴스하지 않는 예전 IP는 제외했습니다. `tb_DWC_compare.sv`는 baseline과 developed의 전체 출력을 비교하는 재현 가능한 검증용 테스트벤치입니다. 두 COE는 BRAM XCI가 직접 참조하는 초기화 파일이므로 포함했습니다.

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

## Developed 설계

### 개발 목적

Baseline의 critical path는 9개 DSP의 조합 cascade 전체를 통과합니다. 100 MHz에서는 timing을 만족하지만 WNS가 작아 동작 주파수를 높이기 어렵고, BRAM enable이 항상 켜져 있어 사용하지 않는 구간에도 내부 동작이 발생합니다. Developed 설계는 DSP 수 9개와 BRAM 용량을 유지하면서 다음을 개선하는 것을 목표로 합니다.

- 긴 DSP cascade를 줄여 setup timing 여유 확보
- 사용하지 않는 weight BRAM read 비활성화
- `keep` 속성 제거로 합성기의 불필요한 논리 제거와 병합 허용
- 결과값과 steady-state 처리량 유지

### 변경한 구조

```text
Baseline : DSP0 -> DSP1 -> DSP2 -> DSP3 -> DSP4 -> DSP5 -> DSP6 -> DSP7 -> DSP8 -> result FF

Developed: DSP0 -> DSP1 -> DSP2 -> partial-sum FF
                                      |
             DSP3 -> DSP4 -> DSP5 <- C input
                         -> partial-sum FF
                                      |
             DSP6 -> DSP7 -> DSP8 <- C input -> result FF
```

DSP 그룹 경계에 48비트 partial-sum register 두 개를 추가하고, 뒤쪽 그룹의 window와 weight도 같은 수의 클럭만큼 지연시켜 연산 샘플을 정렬했습니다. 그 결과 `result_valid`와 `done` latency는 4클럭에서 6클럭으로 증가하지만, pipeline이 채워진 이후 처리량은 동일합니다.

DSP48E2의 전용 `PCIN`은 다른 DSP48E2의 `PCOUT`으로만 구동할 수 있습니다. 따라서 일반 FF에 저장한 partial sum을 다음 DSP의 `PCIN`으로 넣지 않고, 그룹 첫 DSP가 `A*B+C`를 수행하도록 일반 48비트 `C` 입력에 연결했습니다. 이 두 그룹 시작점은 `DWC_developed.sv` 내부의 `dsp_mul_add_c`가 직접 DSP48E2를 인스턴스하며, 합성 후 전체 DSP 수는 여전히 9개입니다.

BRAM enable은 다음과 같이 동작합니다.

- Input BRAM: 전체 입력 scan과 마지막 read pipeline drain 동안 활성화
- Weight BRAM: 채널별 weight 9개를 읽는 구간과 마지막 read pipeline drain 동안만 활성화

### XSim 검증

`tb_DWC_compare.sv`는 developed 출력을 baseline보다 2클럭 지연한 결과와 비교합니다.

| 검증 항목 | 결과 |
| --- | ---: |
| 예상/실제 출력 수 | 75,264 / 75,264 |
| 데이터 mismatch | 0 |
| 첫 `result_valid` 증가 latency | 2클럭, 20 ns |
| `done` 증가 latency | 2클럭, 20 ns |
| active cycles | 86,400 |
| input BRAM enable cycles | 86,402 |
| weight BRAM enable cycles | 4,224 |

Weight BRAM enable은 active 구간의 약 4.89%만 활성화됐습니다. Input BRAM은 연산 중 계속 필요하므로 주로 연산 사이 idle 구간에서 절감 효과가 있습니다.

### PPA 결과

아래 값은 Vivado 2023.2, `xczu3eg-sbva484-1-i`, 10 ns clock constraint의 routed 결과입니다. 저장소의 Vivado 2020.2 및 `-1-e` 환경에서는 배치배선과 timing 수치가 달라질 수 있습니다.

| 항목 | Baseline | Developed | 변화 |
| --- | ---: | ---: | ---: |
| LUT | 954 | 373 | -581, -60.9% |
| FF | 793 | 1,185 | +392, +49.4% |
| BRAM tile | 37.5 | 37.5 | 동일 |
| DSP48E2 | 9 | 9 | 동일 |
| Setup WNS | +0.718 ns¹ | +4.875 ns | +4.157 ns |
| Hold WHS | +0.029 ns | +0.027 ns | 모두 만족 |
| Pulse-width WPWS | +4.457 ns | +4.427 ns | 모두 만족 |
| Total power | 0.291 W | 0.282 W | -3.1% |
| Dynamic power | 0.070 W | 0.061 W | -12.9% |

¹ Setup baseline은 공정한 timing 비교를 위해 `keep`을 제거하고 다시 구현한 결과입니다. LUT/FF baseline은 기존 `keep` 포함 구현 보고서이므로 LUT 감소량에는 `keep` 제거 효과와 developed 구조 변경 효과가 함께 포함됩니다.

명시적으로 추가한 pipeline storage는 operand 정렬 288비트, partial sum 96비트, valid/done 4비트로 약 388 FF입니다. 실제 routed 보고서에서는 합성 최적화 차이를 포함해 baseline 대비 392 FF가 증가했습니다. 반면 `keep` 제거로 LUT가 크게 줄었습니다.

Baseline의 critical path는 9개 DSP를 통과하는 8.738 ns 경로였지만, developed에서는 DSP chain이 critical path에서 제외됐습니다. 새 critical path는 channel/address 제어에서 input BRAM enable까지의 4.556 ns 경로입니다. Power 값은 vectorless activity 기반이며 confidence level이 `Medium`이므로 절대 전력보다 상대 경향으로 해석해야 합니다.

## Vivado에 추가하는 방법

1. Ultra96-V2용 프로젝트를 만들고 part를 `xczu3eg-sbva484-1-e`로 설정합니다.
2. `DWC_baseline.sv`를 Design Sources에 추가합니다.
3. 네 개의 XCI를 모두 Design Sources에 추가하고 IP output products를 생성합니다.
4. `100MHz.xdc`를 Constraints에 추가합니다.
5. 비교 대상에 따라 design top을 `DWC_baseline` 또는 `DWC_developed`로 설정합니다.
6. 비교 simulation을 실행하려면 `tb_DWC_compare.sv`를 Simulation Sources에 추가하고 simulation top으로 설정합니다.

디렉터리 구조를 그대로 유지하면 BRAM XCI의 상대 경로가 `coe/input_bram_easy.coe`와 `coe/weight_rom_easy.coe`를 가리킵니다. 다른 초기화 데이터를 사용할 때는 Block Memory Generator에서 COE를 다시 선택한 뒤 output products를 재생성해야 합니다.
