# MobileNetV2 하드웨어 설계 시 고려할 점

## 1. 대상 환경

- FPGA 보드: Ultra96-V2
- FPGA 디바이스: Zynq UltraScale+ MPSoC ZU3EG
- 개발 도구: Vivado / Vitis 2020.2
- 기준 모델: `C/src/MobileNetV2_full.c`
- 레이어 규격: `C/header/Layer_Spec.h`
- 현재 C 모델 데이터 형식: FP32
- 현재 C 모델 feature map 배치: CHW

ZU3EG PL의 주요 자원은 다음과 같다.

| 자원 | 수량 |
|---|---:|
| LUT | 70,560 |
| FF | 141,120 |
| DSP48E2 | 360 |
| 36Kb BRAM | 216 |
| 총 BRAM 용량 | 약 7.6Mbit, raw 기준 약 972KiB |
| UltraRAM | 없음 |

BRAM의 7.6Mb는 byte가 아니라 bit 단위라는 점에 주의한다. 메모리 폭과 깊이에 따른 단편화까지 고려하면 972KiB를 전부 유효 데이터 저장에 사용할 수는 없다.

## 2. 현재 모델의 규모

현재 C 모델을 기준으로 zero-padding 위치의 곱셈까지 포함하여 계산한 대략적인 연산량은 다음과 같다.

| 연산 종류 | MAC 수 | 비율 |
|---|---:|---:|
| 첫 번째 3×3 convolution | 약 10.84M | 3.6% |
| Depthwise convolution | 약 20.72M | 6.9% |
| Pointwise convolution 및 classifier | 약 269.22M | 89.5% |
| 전체 | 약 300.77M | 100% |

메모리 규모는 다음과 같다.

| 항목 | 크기 |
|---|---:|
| FP32 전체 파라미터 | 약 13.50MiB |
| INT8 convolution/classifier weight | 약 3.31MiB |
| 최대 일반 feature map | INT8 약 392KiB |
| Layer 2 전체 expanded feature | INT8 약 1.15MiB |
| Classifier weight만 | INT8 약 1.28MiB |

따라서 다음 방식은 ZU3EG에서 현실적이지 않다.

- 모든 weight를 BRAM에 동시에 저장
- expanded feature map 전체를 매번 BRAM에 생성
- 전체 모델을 FP32 연산기로 구현
- 레이어마다 전용 연산기를 별도로 생성

권장 방향은 **INT8 재사용 연산기 + BRAM 타일 버퍼 + PS DDR의 backing storage** 구조이다.

## 3. 수치 표현과 정수화

### 권장 데이터 형식

- Activation: INT8
- Weight: INT8
- Bias: INT32
- Accumulator: INT32
- 출력 변환: 정수 multiplier, shift, rounding, saturation

FP32 multiplier, divider, square root IP를 전체 네트워크에 사용하면 DSP/LUT 사용량과 latency가 크게 증가한다. 현재 FP32 C 코드는 golden reference로 두고, RTL과 동일한 연산 규칙을 갖는 bit-accurate 정수 C 모델을 별도로 만드는 것이 좋다.

### Batch Normalization folding

Batch Normalization은 convolution weight와 bias에 미리 결합한다.

```text
alpha[c] = gamma[c] / sqrt(variance[c] + epsilon)

folded_weight[c] = alpha[c] * weight[c]
folded_bias[c]   = beta[c] - alpha[c] * mean[c]
```

이를 통해 RTL에서 sqrt와 division을 제거할 수 있다.

### 정수화 시 결정할 사항

- activation scale을 layer 단위로 할지 tensor 단위로 할지
- weight scale을 tensor 단위 또는 output-channel 단위로 할지
- symmetric 또는 asymmetric quantization
- rounding 방식
- saturation 범위
- accumulator bit width
- ReLU6의 정수 threshold
- residual branch 사이의 scale 정렬 방법

초기 RTL은 zero-point 처리가 필요 없는 symmetric INT8로 시작하는 것이 단순하다. 정확도 개선이 필요하면 per-output-channel weight scale을 적용한다.

## 4. PS와 PL의 역할 분할

### PL에서 처리하기 좋은 작업

- 3×3 stem convolution
- Expansion pointwise convolution
- Depthwise convolution
- Projection pointwise convolution
- Requantization
- ReLU6
- Residual addition
- Global average pooling

### PS에서 처리하기 좋은 작업

- 이미지 입력 및 전처리
- Weight와 layer descriptor 전송
- Accelerator 시작/완료 제어
- DMA cache 관리
- 최종 1280→1000 classifier
- Softmax 및 top-k

Classifier는 전체 연산량에서 차지하는 비중은 작지만 weight가 INT8 기준 1.28MB이다. 이를 PS에서 처리하면 PL의 weight buffer 요구량을 크게 줄일 수 있다.

Softmax는 순위를 바꾸지 않으므로 top-1/top-5 결과만 필요하면 생략하거나 PS에서 계산할 수 있다.

## 5. 메모리 구조

### BRAM의 역할

Block Memory Generator는 전체 모델 저장소보다 다음 용도의 scratchpad로 사용하는 것이 적합하다.

- 현재 activation tile
- 다음 activation tile
- 현재 weight tile
- 다음 weight tile
- Depthwise line buffer
- Partial sum 또는 output tile
- Residual용 input tile

### 권장 버퍼 구조

```text
Activation BRAM A ─┐
                   ├─ ping-pong
Activation BRAM B ─┘

Weight BRAM A ─────┐
                   ├─ ping-pong
Weight BRAM B ─────┘

Accumulator BRAM 또는 register array
Depthwise 3-row line buffer
```

### 용량보다 포트와 bandwidth가 중요함

병렬 multiplier가 64개라고 해도 activation과 weight를 한 cycle에 공급하지 못하면 DSP가 대기한다. 하나의 큰 BRAM보다 병렬도에 맞춘 banking이 필요하다.

- Activation은 input-channel lane 기준으로 bank 분할
- Weight는 input/output-channel lane에 맞춰 wide word로 packing
- Input, weight, output/partial sum은 서로 다른 BRAM에 저장
- PS가 다음 tile을 적재하는 동안 accelerator가 현재 tile을 처리하도록 double buffering
- 동일 bank의 동일 주소 read/write 충돌 조건 확인
- BMG read latency를 `valid` pipeline에 반영

전체 BRAM을 reset으로 초기화하지 않는다. 첫 accumulation cycle에서 accumulator 입력을 0 또는 bias로 선택하면 별도의 memory clear 시간을 줄일 수 있다.

## 6. 타일링과 연산 fusion

Layer 2 expanded feature는 INT8이어도 전체 BRAM보다 크므로 전체 expanded feature를 저장하지 않아야 한다.

권장 처리 순서는 다음과 같다.

```text
for each spatial tile:
    output accumulator 초기화

    for each expanded-channel tile:
        expansion pointwise
        depthwise용 작은 tile/line buffer에 저장
        depthwise 3×3
        projection partial sum 누적

    projection requantization
    residual addition
    output tile 저장
```

타일 경계에서는 3×3 convolution에 필요한 halo를 처리해야 한다.

- halo 중복 읽기
- halo 중복 계산
- 인접 tile과 line buffer 공유

초기 구현은 일부 중복 연산을 허용하더라도 주소 제어가 단순한 방식을 선택하는 것이 좋다.

## 7. 데이터 배치

현재 C 구현은 다음과 같은 CHW 배치를 사용한다.

```text
input[channel][row][column]
```

Pointwise convolution은 한 pixel의 여러 channel을 동시에 읽어야 하므로 blocked NHWC 배치가 더 적합하다.

```text
activation[row][column][channel_group][channel_lane]
```

예를 들어 input-channel 병렬도가 8이라면 channel 8개를 하나의 BRAM word에 저장한다.

Pointwise weight는 다음 순서로 packing할 수 있다.

```text
weight[out_group][in_group][out_lane][in_lane]
```

Depthwise weight는 다음과 같이 packing할 수 있다.

```text
weight[channel_group][kernel_position][channel_lane]
```

Vitis 애플리케이션 또는 별도 변환 도구에서 C 모델의 CHW binary와 weight를 accelerator용 순서로 변환해야 한다.

## 8. 연산기 구성

### Pointwise engine

전체 연산량의 약 90%를 차지하므로 DSP 병렬화의 우선순위가 가장 높다.

예시 시작 구성:

- `PIN=8`
- `POUT=8`
- 8×8 MAC array
- multiplier 64개

### Depthwise engine

3×3 window를 매 cycle 계산하려면 채널 하나당 multiplier 9개가 필요하다.

예시:

- 동시에 8채널 처리
- 8×9=72 multiplier
- 3-row line buffer

Depthwise 연산량은 적으므로 DSP가 부족할 경우 multiplier를 시간 재사용하는 방법도 고려할 수 있다.

### DSP 사용 방식

다음 선택지가 있다.

- DSP Macro/Multiplier IP 사용
- DSP48E2 primitive 직접 instantiation
- `a * b + accumulator` RTL 작성 후 DSP inference

초기 구현은 inference 방식이 유지보수하기 쉽다. 합성 후 `report_utilization`과 schematic으로 실제 DSP48E2 매핑을 확인한다.

## 9. 제어 구조

레이어별 전용 모듈을 만드는 대신 하나의 연산기를 descriptor 기반으로 재사용하는 것이 좋다.

Layer descriptor에 들어갈 수 있는 항목:

```text
operation type
input H/W/C
output H/W/C
expanded channel 수
stride
padding
input/output/weight base address
quantization multiplier와 shift
ReLU6 enable
residual enable
```

권장 RTL 모듈 분할:

```text
mobilenet_accel_top
layer_controller
layer_descriptor_rom
pw_conv_engine
dw_conv_3x3_engine
line_buffer_3x3
mac_array
requant_relu6
residual_add
global_avg_pool
bram_bank_controller
axi_lite_regs
```

## 10. Vivado/Vitis 통합

### Vivado Block Design

- Zynq UltraScale+ Processing System
- Processor System Reset
- AXI Interconnect 또는 SmartConnect
- AXI4-Lite control register
- AXI DMA 또는 AXI BRAM Controller
- Block Memory Generator
- Custom accelerator RTL
- Interrupt

첫 구현에서는 하나의 PL clock으로 시작한다. 100MHz에서 기능과 timing을 확보한 뒤 150MHz 이상으로 높이는 것이 좋다.

### Vitis 프로그램

- Accelerator용 activation/weight 배치 변환
- BRAM 또는 DDR 주소 설정
- Control register 설정
- `start` 전송
- interrupt 또는 `done` polling
- 결과 회수 및 golden result 비교

DMA를 사용하면 cache flush/invalidate가 누락되지 않도록 한다.

## 11. 검증 전략

현재 `C/bin`에 저장된 레이어별 FP32 결과를 golden reference로 활용할 수 있다. 정수 RTL과 직접 bit-exact 비교하기 위해서는 별도의 정수 C reference가 필요하다.

권장 순서:

1. BN-folded FP32 모델과 기존 FP32 모델 비교
2. INT8 bit-accurate C 모델 작성
3. Pointwise 단일 output 검증
4. Pointwise 전체 작은 tensor 검증
5. Depthwise stride 1 검증
6. Depthwise stride 2와 padding 검증
7. Requantization과 ReLU6 검증
8. Residual block 검증
9. 전체 레이어 intermediate result 비교
10. Post-synthesis timing simulation
11. Ultra96-V2에서 ILA 검증

자주 발생하는 오류:

- signed/unsigned 혼용
- weight sign extension 누락
- accumulator overflow
- rounding과 saturation 방식 불일치
- CHW/NHWC 순서 불일치
- padding 값 오류
- stride 2 output 주소 오류
- BMG read latency 누락
- DSP pipeline latency와 write address 불일치
- residual scale 불일치

## 12. 권장 개발 순서

1. INT8 pointwise convolution 연산 규격 확정
2. Pointwise MAC array 구현
3. BRAM banking과 주소 생성기 연결
4. Pointwise layer 검증
5. Depthwise line-buffer engine 구현
6. Requantization/ReLU6 구현
7. Inverted residual block 하나 완성
8. Layer descriptor 기반 전체 실행
9. PS classifier와 Vitis driver 연결
10. 합성 결과에 따라 DSP 병렬도와 tile 크기 조정

가장 중요한 기준은 **BRAM에 전체 데이터를 저장하는 것보다 DSP에 매 cycle 데이터를 끊기지 않고 공급하는 것**이다.
