# Layer 8 Expansion Pointwise Weight ROM 명세

## 1. 대상 연산

```text
Cin  = 64
Cout = 384
H = W = 14

Pin  = 4
Pout = 1
```

Weight tensor:

```text
weight[Cout][Cin][1][1]
weight[384][64][1][1]
```

`Pin=4`이므로 동일한 filter에서 연속된 input-channel weight 4개를 매 cycle 읽는다.

## 2. Block Memory Generator 설정

| 설정 | 값 |
|---|---:|
| Memory Type | Single Port ROM |
| Algorithm | Minimum Area |
| Write Width | 사용하지 않음 |
| Read Width | 64bit |
| Read Depth | 6,144 |
| Address Width | 13bit |
| Enable Port | 필요에 따라 사용 |
| Initialization | COE file |
| COE | `Verilog/mem/layer8_expansion_weight_pin4_test.coe` |

논리적인 저장 용량:

```text
64bit × 6,144
= 393,216bit
= 24,576개의 16bit weight
```

RAMB36E2의 물리 배치와 BMG 설정에 따라 차이가 날 수 있지만 약 12개의 36Kb BRAM이 예상된다. 최종 수량은 Vivado `report_utilization`에서 확인한다.

## 3. ROM 주소

정의:

```text
n       = output channel/filter index, 0..383
m_group = input channel group index, 0..15
lane    = group 내부 input channel, 0..3
```

주소:

```text
rom_addr = n × (Cin/Pin) + m_group
         = n × 16 + m_group
```

유효 주소:

```text
0..6,143
```

13bit address의 나머지 `6,144..8,191` 구간은 접근하지 않는다.

## 4. ROM word packing

한 ROM word는 같은 filter `n`의 연속된 weight 4개를 담는다.

```text
dout[15:0]  = weight[n][m_group×4 + 0]
dout[31:16] = weight[n][m_group×4 + 1]
dout[47:32] = weight[n][m_group×4 + 2]
dout[63:48] = weight[n][m_group×4 + 3]
```

RTL unpack 예시:

```systemverilog
logic signed [15:0] weight_lane [0:3];

assign weight_lane[0] = $signed(weight_rom_dout[15:0]);
assign weight_lane[1] = $signed(weight_rom_dout[31:16]);
assign weight_lane[2] = $signed(weight_rom_dout[47:32]);
assign weight_lane[3] = $signed(weight_rom_dout[63:48]);
```

## 5. 검증용 weight 값

현재 COE는 실제 학습 weight가 아니라 다음 결정론적 signed 정수 패턴을 사용한다.

```text
weight[n][m] = ((n × 5 + m × 3) mod 16) - 8
```

값의 범위:

```text
-8..7
```

작은 signed 정수이므로 waveform과 정수 golden model에서 결과를 확인하기 쉽다.

예를 들어 `n=0`, `m_group=0`이면:

```text
weight[0][0] = -8 = 16'hFFF8
weight[0][1] = -5 = 16'hFFFB
weight[0][2] = -2 = 16'hFFFE
weight[0][3] =  1 = 16'h0001
```

COE에는 MSB lane부터 기록되므로 첫 word는 다음과 같다.

```text
0001FFFEFFFBFFF8
```

## 6. COE 재생성

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File `
  .\Verilog\tools\generate_layer8_expansion_test_weight_coe.ps1
```

실제 weight를 적용할 때는 생성 스크립트의 `Get-TestWeight` 대신 다음 처리를 넣는다.

1. `features_8_conv_0_0_weight[24576]`을 읽는다.
2. 결정한 fixed-point scale로 signed 16bit 변환한다.
3. 같은 `n`, 연속된 `m` 네 개를 현재 lane 순서로 packing한다.
4. 64bit word 6,144개를 COE로 출력한다.

## 7. Latency 주의

Block ROM은 synchronous read이므로 address를 전달한 cycle과 `dout`이 유효한 cycle이 다르다.

```text
cycle k:   rom_addr 제시
cycle k+L: weight_rom_dout 유효
```

`L`은 BMG output register 설정에 따라 정한다. Input RAM과 Weight ROM의 latency를 같게 구성하거나, 짧은 쪽에 register를 추가하여 DSP 입력 시점을 맞춘다.

