# Pointwise Convolution Verilog 구현 시 고려할 점

## 1. 이번 주 구현 범위

이번 주에는 전체 MobileNetV2가 아니라 **1×1 pointwise convolution 연산기 하나를 정확하게 구현하고 검증하는 것**을 목표로 한다.

처음부터 다음 기능까지 모두 넣으려고 하지 않는 것이 좋다.

- Batch Normalization
- ReLU6
- Requantization
- AXI DMA
- 전체 MobileNetV2 layer controller
- Depthwise convolution

이번 주 최소 완료 조건은 다음과 같다.

```text
BRAM에 저장된 input과 weight 읽기
→ signed multiply
→ input channel 방향 누적
→ output BRAM에 결과 저장
→ C 또는 testbench golden result와 비교
```

첫 버전은 작은 tensor로 검증한 뒤 실제 MobileNetV2 크기로 확장한다.

## 2. Pointwise convolution 연산 정의

입력이 `H×W×Cin`, 출력이 `H×W×Cout`이면 연산은 다음과 같다.

```text
output[oc][y][x] =
    sum(input[ic][y][x] * weight[oc][ic])
    for ic = 0 ... Cin-1
```

1×1 convolution이므로 다음 특성이 있다.

- 입력과 출력의 H, W는 동일
- padding이 필요 없음
- 한 출력 pixel은 동일 위치의 모든 input channel을 사용
- 한 weight는 모든 spatial position에서 재사용
- 서로 다른 output channel은 독립적으로 계산 가능

현재 C 구현의 주소식은 다음과 같다.

```c
output[oc * height * width + y * width + x] +=
    input[ic * height * width + y * width + x]
    * weight[oc * in_ch + ic];
```

즉 현재 C binary는 CHW 순서이다.

## 3. 먼저 확정해야 할 설계 파라미터

RTL 작성 전에 다음을 parameter로 정한다.

```verilog
parameter DATA_W = 8;
parameter WEIGHT_W = 8;
parameter ACC_W = 32;
parameter H_MAX = 112;
parameter W_MAX = 112;
parameter CIN_MAX = 1280;
parameter COUT_MAX = 1280;
```

이번 주에는 실제 최대 크기와 별개로 다음과 같은 작은 검증 설정을 먼저 사용하는 것이 좋다.

```text
H=2, W=2, Cin=4, Cout=3
```

작은 설정으로 모든 결과를 손으로도 확인한 후 다음 레이어를 시험한다.

```text
MobileNetV2 Layer 1 projection
H=112, W=112, Cin=32, Cout=16
```

## 4. 수치 형식

### 권장 첫 구현

- Input: signed INT8
- Weight: signed INT8
- Product: signed INT16
- Accumulator: signed INT32
- Output: signed INT32

이번 주에는 출력 requantization을 제외하고 INT32 accumulation 결과를 저장하는 것이 검증하기 쉽다.

```verilog
logic signed [7:0]  input_data;
logic signed [7:0]  weight_data;
logic signed [15:0] product;
logic signed [31:0] accumulator;
```

### Signed 연산 주의

Verilog에서는 operand 하나라도 unsigned이면 예상하지 못한 unsigned multiply가 될 수 있다.

안전한 형태의 예:

```verilog
logic signed [DATA_W-1:0]   act_s;
logic signed [WEIGHT_W-1:0] weight_s;
logic signed [DATA_W+WEIGHT_W-1:0] mult_s;

assign mult_s = act_s * weight_s;
```

BRAM 출력 wire와 module port에도 `signed`가 유지되는지 확인한다. 필요하면 `$signed()`를 명시한다.

### Accumulator 폭

최대 누적 항 수가 `Cin`이므로 보수적인 accumulator 폭은 다음처럼 생각할 수 있다.

```text
ACC_W >= DATA_W + WEIGHT_W + ceil(log2(Cin))
```

MobileNetV2의 최대 Cin까지 고려하면 INT32면 충분한 여유가 있다. 그러나 최종 설계에서는 실제 quantization 범위와 bias 범위를 포함해 overflow를 다시 계산해야 한다.

## 5. 가장 단순한 데이터패스

첫 번째 버전은 multiplier 하나를 시간 재사용하는 구조가 가장 단순하다.

```text
Input BRAM ─┐
            ├─ multiplier ─ accumulator ─ Output BRAM
Weight BRAM ┘
```

동작 순서:

```text
for oc:
    for y:
        for x:
            accumulator = 0

            for ic:
                accumulator += input[y][x][ic] * weight[oc][ic]

            output[y][x][oc] = accumulator
```

장점:

- 주소 제어가 단순함
- DSP 1개로 구현 가능
- golden 결과와 비교하기 쉬움
- 이후 병렬 구조의 기준 RTL로 사용할 수 있음

단점:

- 한 output을 만드는 데 Cin cycle 이상 필요
- 전체 MobileNetV2 실행에는 너무 느림

이번 주 과제에서 성능 목표가 명확하지 않다면 먼저 이 구조를 정확하게 완성하고, 그다음 병렬화를 추가하는 것이 좋다.

## 6. 권장 병렬 구조

성능 확장 시 input channel과 output channel을 동시에 병렬화한다.

```text
PIN  = 한 cycle에 처리하는 input channel 수
POUT = 동시에 계산하는 output channel 수
DSP 수 = PIN × POUT
```

예:

```text
PIN=4, POUT=4 → DSP 16개
PIN=8, POUT=8 → DSP 64개
```

8×8 MAC array 개념:

```text
activation 8개
    │
    ├─ output channel 0의 weight 8개 → dot product → acc[0]
    ├─ output channel 1의 weight 8개 → dot product → acc[1]
    ├─ ...
    └─ output channel 7의 weight 8개 → dot product → acc[7]
```

대략적인 계산 cycle은 다음과 같다.

```text
cycles ≈ H × W
         × ceil(Cin / PIN)
         × ceil(Cout / POUT)
```

여기에 BRAM latency, pipeline fill/flush, output write cycle이 추가된다.

처음부터 8×8이 부담스럽다면 다음 단계로 확장할 수 있다.

1. 1×1 scalar MAC
2. `PIN=4, POUT=1`
3. `PIN=4, POUT=4`
4. `PIN=8, POUT=8`

## 7. Adder tree

`PIN`개의 곱 결과를 한 cycle에 생성하면 이들을 더하는 adder tree가 필요하다.

`PIN=8` 예:

```text
Level 1: p0+p1, p2+p3, p4+p5, p6+p7
Level 2: s0+s1, s2+s3
Level 3: t0+t1
```

조합 논리로 한 cycle에 모두 더하면 critical path가 길어진다. 각 level에 pipeline register를 둘지 결정해야 한다.

고려할 점:

- Adder tree latency
- DSP multiplier latency
- `valid` 신호 지연
- 어느 output channel과 pixel의 결과인지 나타내는 metadata 지연
- 마지막 input-channel group인지 나타내는 `ic_last` 지연

데이터와 제어 신호는 같은 cycle 수만큼 pipeline되어야 한다.

## 8. DSP IP 사용

선택지는 다음과 같다.

### 방법 A: RTL inference

```verilog
acc <= acc + $signed(act) * $signed(weight);
```

장점:

- parameter/generate 사용이 쉬움
- RTL이 단순함
- 병렬도 변경이 쉬움

합성 후 multiplier가 DSP48E2로 매핑됐는지 확인해야 한다.

### 방법 B: Multiplier 또는 DSP Macro IP

장점:

- latency를 명시적으로 설정 가능
- DSP 사용을 확실하게 제어 가능

주의:

- IP에서 설정한 latency를 controller에 반영해야 함
- lane 수가 많으면 IP instance 관리가 복잡해짐
- simulation library 설정이 필요할 수 있음

이번 과제에서는 RTL inference로 시작한 뒤 필요할 때 IP로 교체하는 방법이 적합하다.

## 9. BRAM 데이터 배치

### 방법 A: 현재 C와 같은 CHW

주소:

```text
input_addr  = ic × H × W + y × W + x
weight_addr = oc × Cin + ic
output_addr = oc × H × W + y × W + x
```

장점:

- 현재 C binary와 직접 비교하기 쉬움
- scalar MAC 구현에 적합

단점:

- 여러 input channel을 동시에 읽기 어려움
- `PIN>1`이면 여러 BRAM bank 또는 복제 필요

### 방법 B: Blocked NHWC

주소 개념:

```text
input[y][x][ic_group] = PIN개의 channel이 packing된 word
```

Weight:

```text
weight[oc_group][ic_group] =
    POUT × PIN개의 weight가 packing되거나 bank로 분리됨
```

장점:

- 병렬 MAC array에 데이터를 공급하기 쉬움
- wide BRAM word 사용 가능

단점:

- C 입력과 weight의 사전 변환 필요
- 주소와 packing 검증이 추가로 필요

이번 주 scalar 버전은 CHW로 구현해도 된다. 병렬 버전까지 목표라면 blocked NHWC 또는 banked CHW 중 하나를 명확히 선택해야 한다.

## 10. BRAM 포트 구성

Input, weight, output을 하나의 BRAM에 넣으면 읽기 두 번과 쓰기 한 번이 동시에 필요해 포트가 부족하다. 최소한 논리적으로 다음처럼 분리한다.

```text
Input BRAM
Weight BRAM
Output BRAM
```

Block Memory Generator 설정 시 확인할 항목:

- Single Port / Simple Dual Port / True Dual Port
- read-first, write-first, no-change 모드
- read latency
- output register 사용 여부
- memory initialization file 사용 여부
- data width와 depth

과제용 구조에서는 다음 구성이 단순하다.

- Input BMG: accelerator read, testbench/PS write
- Weight BMG: accelerator read, testbench/PS write
- Output BMG: accelerator write, testbench/PS read

BMG가 synchronous read이면 주소를 제시한 cycle과 데이터가 나오는 cycle이 다르다. 다음과 같이 생각해야 한다.

```text
cycle N:     read address 출력
cycle N+1:   BRAM data 유효
cycle N+L:   DSP/adder 결과 유효
```

## 11. FSM 설계

Scalar MAC 기준으로 다음 상태가 있으면 이해하기 쉽다.

```text
IDLE
LOAD_ADDR
WAIT_BRAM
MAC
WRITE
DONE
```

실제로는 BRAM과 DSP latency에 따라 상태를 합치거나 pipeline할 수 있다.

필요한 loop counter:

```text
x_count
y_count
ic_count
oc_count
```

카운터 갱신 우선순위 예:

```text
ic가 마지막:
    output write
    ic = 0

    x가 마지막:
        x = 0

        y가 마지막:
            y = 0
            oc 증가
        아니면:
            y 증가
    아니면:
        x 증가
아니면:
    ic 증가
```

마지막 output까지 BRAM write가 끝난 뒤 `done`을 발생시켜야 한다. 마지막 MAC을 실행한 즉시 `done`을 올리면 pipeline에 남은 결과가 저장되지 않을 수 있다.

## 12. 권장 인터페이스

과제용 core는 AXI를 바로 넣기보다 단순한 제어 인터페이스로 먼저 만드는 것이 좋다.

```verilog
module pointwise_conv #(
    parameter DATA_W   = 8,
    parameter WEIGHT_W = 8,
    parameter ACC_W    = 32,
    parameter ADDR_W   = 24
) (
    input  logic clk,
    input  logic rst_n,

    input  logic start,
    output logic busy,
    output logic done,

    input  logic [15:0] height,
    input  logic [15:0] width,
    input  logic [15:0] in_channels,
    input  logic [15:0] out_channels,

    output logic [ADDR_W-1:0] input_addr,
    input  logic signed [DATA_W-1:0] input_rdata,

    output logic [ADDR_W-1:0] weight_addr,
    input  logic signed [WEIGHT_W-1:0] weight_rdata,

    output logic [ADDR_W-1:0] output_addr,
    output logic signed [ACC_W-1:0] output_wdata,
    output logic output_we
);
```

먼저 위와 같은 native memory interface core를 검증하고, 이후 wrapper에서 BMG나 AXI BRAM Controller에 연결한다.

## 13. 첫 버전에서 생각할 최적화

정확한 scalar 버전이 동작한 이후 다음 순서로 최적화한다.

### Weight reuse

동일한 `weight[oc][ic]`는 모든 `H×W` 위치에서 사용된다. 따라서 weight를 한 번 BRAM에서 읽어 register/local buffer에 보관하는 방법을 고려한다.

다만 전체 output channel의 weight를 register로 펼치면 자원이 커지므로 output-channel tile 단위로 저장한다.

### Output-channel 병렬화

같은 input activation을 여러 output channel이 공유할 수 있다.

```text
input 하나를 읽음
→ 서로 다른 POUT개의 weight와 곱함
→ POUT개의 accumulator 갱신
```

따라서 `POUT` 병렬화는 input BRAM bandwidth를 크게 늘리지 않고 DSP 활용도를 높일 수 있다.

### Input-channel 병렬화

`PIN`을 늘리면 한 output의 dot product cycle이 줄어든다. 대신 다음 자원이 필요하다.

- `PIN`개 activation 공급
- `PIN×POUT`개 weight 공급
- `PIN×POUT`개 multiplier
- POUT개의 adder tree

대부분의 경우 output-channel 병렬화부터 적용한 뒤 input-channel 병렬화를 늘리는 편이 메모리 설계가 쉽다.

## 14. Testbench 전략

### 단계 1: 가장 작은 directed test

```text
H=1, W=1, Cin=2, Cout=2
```

예:

```text
input  = [2, -3]
weight output 0 = [4, 5]
weight output 1 = [-2, 7]

output 0 = 2×4 + (-3)×5 = -7
output 1 = 2×(-2) + (-3)×7 = -25
```

이 테스트로 signed multiply와 accumulation을 확인한다.

### 단계 2: Spatial address 검증

```text
H=2, W=2, Cin=2, Cout=1
```

각 pixel의 값이 다르게 입력되어야 x/y 주소 오류를 찾을 수 있다.

### 단계 3: Output-channel 주소 검증

```text
H=2, W=2, Cin=2, Cout=3
```

output channel별 weight를 크게 다르게 설정한다.

### 단계 4: Random test

- 작은 random signed INT8 입력 생성
- C 또는 testbench function으로 golden INT32 계산
- RTL output과 모든 원소를 exact 비교

### 단계 5: 실제 레이어

MobileNetV2 Layer 1 projection:

```text
H=112
W=112
Cin=32
Cout=16
```

FP32 원본과 비교하지 말고, 동일한 INT8 input/weight를 사용하는 정수 golden model과 비교한다.

## 15. 디버깅할 신호

Waveform 또는 ILA에서 다음 신호를 보는 것이 좋다.

```text
state
start, busy, done
x_count, y_count, ic_count, oc_count
input_addr, input_rdata
weight_addr, weight_rdata
mult_result
accumulator
output_addr, output_wdata, output_we
data_valid
ic_last
```

주소와 데이터가 한 cycle씩 어긋나는 오류가 가장 흔하므로, `read address → BRAM output → DSP input → accumulator → output write` 흐름을 cycle 단위로 확인한다.

## 16. 이번 주 체크리스트

### 기능 명세

- [ ] 입력/weight/output의 bit width 확정
- [ ] signed 연산 규칙 확정
- [ ] CHW 또는 blocked NHWC 배치 확정
- [ ] BRAM read latency 확정
- [ ] output은 우선 INT32로 저장

### RTL

- [ ] `start`, `busy`, `done` 구현
- [ ] x/y/input-channel/output-channel counter 구현
- [ ] input/weight/output 주소 생성기 구현
- [ ] signed multiplier 구현
- [ ] accumulator 초기화 및 누적 구현
- [ ] 마지막 channel에서 output write
- [ ] 마지막 write 이후 `done` 발생

### 검증

- [ ] 음수 input/weight directed test
- [ ] H/W가 1보다 큰 주소 테스트
- [ ] Cout이 1보다 큰 테스트
- [ ] random small tensor exact 비교
- [ ] synthesis 후 DSP48E2 사용 확인
- [ ] synthesis 후 latch와 timing warning 확인

## 17. 권장 이번 주 결과물

```text
Verilog/
├─ rtl/
│  ├─ pointwise_conv.sv
│  └─ pointwise_mac.sv
├─ tb/
│  └─ tb_pointwise_conv.sv
├─ mem/
│  ├─ input.mem
│  ├─ weight.mem
│  └─ golden_output.mem
└─ docs/
   └─ Pointwise_Conv_RTL_Considerations.md
```

완료 기준:

1. 작은 directed test 통과
2. random tensor 결과가 golden model과 exact match
3. 실제 MobileNetV2 pointwise layer 크기로 simulation 가능
4. Vivado 합성에서 multiplier가 DSP48E2에 매핑
5. BRAM read latency를 포함해 모든 output 주소가 정확함

이번 주에는 고성능보다 **정확한 signed MAC, 정확한 주소 생성, 정확한 BRAM/DSP latency 처리**가 가장 중요하다. 이 기준 설계가 있어야 이후 병렬화 결과도 신뢰할 수 있다.
