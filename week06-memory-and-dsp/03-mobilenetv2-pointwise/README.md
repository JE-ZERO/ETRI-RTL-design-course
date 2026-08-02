# MobileNetV2 Layer 8 Pointwise Convolution

Ultra96-V2에서 MobileNetV2 Layer 8의 expansion pointwise convolution을 구현한 Vivado 프로젝트입니다. DSP 한 개를 사용하는 baseline과 출력 채널 32개를 동시에 계산하는 OS32 구조를 동일한 입력, 가중치, Golden 결과로 비교합니다.

## 설계 사양

| 항목 | 값 |
| --- | ---: |
| 입력 feature map | 64 × 14 × 14 |
| 출력 feature map | 384 × 14 × 14 |
| 전체 출력 수 | 75,264 |
| 전체 MAC 수 | 4,816,896 |
| 입력 형식 | signed 16-bit, F11, CHW |
| 가중치 형식 | signed 16-bit, F13, `[out_channel][in_channel]` |
| 누산 결과 | signed 48-bit, F24 |
| 기준 클럭 | 100 MHz |
| 대상 보드 | Ultra96-V2 |
| 대상 FPGA | `xczu3eg-sbva484-1-i` |
| 개발 도구 | Xilinx Vivado 2023.2 |

Batch normalization, ReLU6, 반올림, 포화 처리와 16비트 재양자화는 현재 범위에 포함하지 않습니다.

## 디렉터리 구성

```text
03-mobilenetv2-pointwise/
├─ Golden/
│  ├─ Simple/                 단순화한 bit-true C 모델
│  └─ generated/              입력·가중치·Golden 결과와 COE
├─ MobileNetV2.srcs/
│  ├─ sources_1/new/          baseline·OS32 RTL
│  ├─ sources_1/ip/           Block Memory·DSP Macro XCI
│  ├─ sim_1/                  baseline·OS32 테스트벤치
│  └─ constrs_1/new/          100 MHz 클럭 제약
├─ docs/                      구조·검증·PPA 정리와 그림
├─ reference/                 초기 Pin=4 ROM 검토 자료
└─ MobileNetV2.xpr            Vivado 프로젝트
```

## 사용 IP

| IP | 설정 | 용도 |
| --- | --- | --- |
| `blk_mem_gen_0` | Simple Dual Port RAM, 16-bit × 12,544, primitive output register | Layer 7 출력 입력값 저장 |
| `blk_mem_gen_1` | Single Port ROM, 16-bit × 24,576, primitive output register | baseline 가중치 저장 |
| `blk_mem_gen_2` | Single Port ROM, 512-bit × 768, primitive output register | OS32용 가중치 32개 packing |
| `dsp_macro_0` | signed 16×16, 48-bit P, `A*B`/`P+A*B` | 곱셈 및 64채널 누산 |

모든 Block Memory의 읽기 지연은 primitive output register를 포함해 2클럭입니다. DSP Macro는 내부 파이프라인을 사용하며 RTL에서 결과 시점에 맞춰 제어 신호를 지연합니다.

## 구현 구조

### Baseline

DSP Macro 한 개를 재사용해 출력 채널, 픽셀, 입력 채널 순서로 계산합니다. 출력 하나마다 64회의 MAC을 수행하며, 계산된 48비트 결과는 `out_valid`와 함께 순차 출력합니다.

### OS32

한 입력값을 32개 DSP Macro에 broadcast하고, 512비트 ROM word에서 출력 채널 32개의 가중치를 동시에 공급합니다. 각 DSP의 partial sum은 입력 채널 64개를 처리하는 동안 DSP 내부 P 레지스터에 유지됩니다. 완성된 32개 결과는 local buffer에 저장한 뒤 한 포트로 직렬 출력합니다.

이 구조는 baseline과 같은 연산 순서를 유지하면서 입력 RAM 읽기 한 번으로 출력 채널 32개를 갱신하므로, 구조 비교가 단순하고 입력 재사용 효과를 직접 확인할 수 있습니다.

## 검증 결과

두 테스트벤치는 실제 Block Memory Generator와 DSP Macro 인스턴스를 사용합니다. C Golden 결과 `layer8_pointwise_acc_simple.mem`과 전체 75,264개 출력을 bit 단위로 비교했습니다.

| 구조 | DSP 수 | 완료 클럭 | 100 MHz 실행 시간 | Golden 비교 |
| --- | ---: | ---: | ---: | --- |
| Baseline | 1 | 4,816,902 | 약 48.17 ms | 전체 일치 |
| OS32 | 32 | 150,566 | 약 1.506 ms | 전체 일치 |

동일한 100 MHz 조건에서 OS32의 측정 속도 향상은 약 31.99배입니다. 완료 클럭에는 BRAM/DSP 파이프라인과 OS32의 32개 결과 직렬 출력 시간이 포함됩니다.

## Implementation 비교

| 항목 | Baseline | OS32 |
| --- | ---: | ---: |
| LUT | 198 | 612 |
| FF | 180 | 2,041 |
| BRAM tile | 18 | 21 |
| DSP | 1 | 32 |
| WNS @ 100 MHz | +7.265 ns | +5.800 ns |
| Total on-chip power | 0.243 W | 0.255 W |

두 구조 모두 100 MHz timing constraint를 만족합니다. 전력값은 vectorless activity 기반 Vivado 추정치이므로 절대값보다는 동일 설정에서의 상대 비교용입니다.

## 실행 방법

1. `MobileNetV2.xpr`을 Vivado 2023.2에서 엽니다.
2. baseline 검증 시 design top을 `pointwise_baseline`, simulation top을 `tb_pointwise_baseline`으로 설정합니다.
3. OS32 검증 시 design top을 `pointwise_os32`, simulation top을 `tb_pointwise_os32`로 설정합니다.
4. Behavioral simulation 또는 post-synthesis functional simulation을 실행합니다.
5. Transcript에서 전체 출력 일치 메시지를 확인합니다.

PPA 비교에서는 같은 XDC와 100 MHz 조건을 사용해야 합니다. 기존 합성 결과나 incremental checkpoint는 포함하지 않았으므로 저장소를 받은 환경에서 synthesis와 implementation을 새로 실행합니다.
