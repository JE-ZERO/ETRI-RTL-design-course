# Week 2 — Verilog RTL: Hexa Multiplier & UART

Vivado에서 8비트 × 8비트 unsigned 곱셈기를 직접 구성하고, UART로 두 피연산자를 받아 계산 결과를 다시 전송하는 시스템까지 연결한 실습입니다. 저장소에는 소스와 재현에 필요한 프로젝트 설정만 포함하며, Vivado가 다시 생성할 수 있는 `.cache`, `.gen`, `.runs`, `.sim`, `ip_user_files`는 제외했습니다.

## 개발 환경

- Xilinx Vivado 2023.2
- FPGA: AMD/Xilinx Zynq UltraScale+ `xczu3eg-sbva484-1-i` (Ultra96-V2)
- 확장 보드: Pmod96 Training Kit 및 Pmod USBUART
- UART 설정: 115200 baud, 8 data bits, no parity, 1 stop bit (8-N-1), flow control 없음

## 프로젝트 구성

```text
week02-verilog-basics/
├── Hexa_Multiplier/   # 8×8 unsigned 곱셈기와 단독 테스트벤치
└── UART/              # UART 송수신기, 곱셈기 연결부, 보드 top/XDC, 통합 테스트벤치
```

- `Hexa_Multiplier/multiplier.xpr`: 곱셈기 단독 Vivado 프로젝트
- `UART/multiplier_uart.xpr`: UART-곱셈기 통합 Vivado 프로젝트

두 프로젝트 폴더 안의 `*.srcs`에는 RTL, 테스트벤치, 제약 파일이 들어 있습니다. UART 프로젝트에는 40 MHz 보드 클록을 100 MHz로 변환하는 Clocking Wizard 설정 `clk_wiz_0.xci`도 포함되어 있습니다.

## 1. Hexa Multiplier

### 설계 방법

입력 `a`와 `b`는 각각 8비트 unsigned 값입니다. 두 입력을 상위/하위 4비트로 나누고 하나의 4×4 곱셈기를 네 번 재사용해 다음 부분곱을 계산합니다.

```text
(a[7:4] × b[7:4]) << 8
(a[7:4] × b[3:0]) << 4
(a[3:0] × b[7:4]) << 4
(a[3:0] × b[3:0])
```

`controller.v`의 FSM이 MUX 선택, 시프트 크기, 누산기 clear/enable을 순서대로 제어합니다. `mult4x4.v`가 만든 8비트 부분곱을 `shifter.v`가 0/4/8비트 이동하고, `accumulator.v`가 네 값을 더해 16비트 `result`를 만듭니다. 네 부분곱의 누산이 끝난 뒤 `done`이 한 상태 동안 올라갑니다.

주요 RTL은 다음과 같습니다.

| 파일 | 역할 |
| --- | --- |
| `hexa_multiplier_top.v` | 데이터패스와 제어기 연결 |
| `controller.v` | IDLE → 네 부분곱 상태 → DONE 순서 제어 |
| `mux.v` | 각 입력의 상위/하위 nibble 선택 |
| `mult4x4.v` | 4×4 unsigned 곱셈 |
| `shifter.v` | 부분곱을 0/4/8비트 정렬 |
| `accumulator.v` | 정렬된 부분곱 누산 |

예를 들어 `8'h12 × 8'h34`는 네 부분곱을 합산해 `16'h03A8`이 됩니다. `hexa_multiplier_tb.v`에서 이 입력으로 동작 파형을 확인할 수 있습니다.

## 2. UART와 곱셈기 연결

### UART 구현

- `baud_rate_generator.v`: 시스템 클록으로부터 RX oversampling tick과 TX baud tick 생성
- `uart_rx.v`: 입력을 2단 동기화한 뒤 16배 oversampling으로 start/data/stop bit 수신
- `uart_tx.v`: start bit, LSB-first 8 data bits, stop bit 순서로 송신
- `uart_multiplier_core.v`: ASCII 명령 해석, 곱셈 요청, 응답 전송을 관리하는 상위 FSM
- `multiplier_adapter.v`: 두 피연산자를 latch하고 곱셈기 reset/start/done 타이밍을 단발성 요청·완료 handshake로 변환
- `uart_multiplier_top.v`: 40 MHz 입력 클록, Clocking Wizard의 100 MHz 출력, reset 동기화, UART core 연결

RX와 TX는 모두 115200 baud, 8-N-1 형식입니다. RX는 대소문자 16진수 문자를 허용하며 공백, CR, LF는 무시합니다. 그 밖의 문자가 들어오면 수신 중이던 명령을 폐기합니다.

### 통신 프로토콜

PC가 16진수 네 글자를 보내면 앞의 두 글자를 `operand_a`, 뒤의 두 글자를 `operand_b`로 사용합니다. 곱셈이 끝나면 FPGA가 `=`, 4자리 대문자 16진수 결과, CR/LF를 차례로 전송합니다.

```text
PC -> FPGA : 1234
FPGA -> PC : =03A8\r\n

PC -> FPGA : FFFF
FPGA -> PC : =FE01\r\n

PC -> FPGA : ab02
FPGA -> PC : =0156\r\n
```

전체 데이터 흐름은 다음과 같습니다.

```text
Pmod USBUART TX
    -> uart_rx
    -> ASCII hex parser (A, B)
    -> multiplier_adapter
    -> hexa_multiplier_top
    -> 16-bit result
    -> ASCII formatter
    -> uart_tx
    -> Pmod USBUART RX
```

## 시뮬레이션

### Vivado

1. 단독 곱셈기는 `Hexa_Multiplier/multiplier.xpr`를 열고 `Run Behavioral Simulation`을 실행합니다.
2. UART 통합 설계는 `UART/multiplier_uart.xpr`를 열고 `tb_uart_multiplier_core`로 Behavioral Simulation을 실행합니다.
3. 통합 테스트벤치는 `1234`, `FFFF`, `ab02` 세 명령의 7바이트 응답을 검사합니다. 성공하면 콘솔에 `ALL TESTS PASSED`가 출력됩니다.

## 보드 시연

1. Ultra96-V2에 Pmod96 Training Kit과 Pmod USBUART를 연결합니다.
2. `UART/multiplier_uart.xpr`를 열고 `clk_wiz_0`의 output products를 생성합니다.
3. `uart_multiplier_top`을 synthesis top으로 설정하고 bitstream을 생성해 보드에 program합니다.
4. PC에서 serial terminal을 115200 baud, 8-N-1, flow control 없음으로 엽니다.
5. `1234`를 전송하고 `=03A8` 응답을 확인합니다.

`ultra96_training_kit_uart_bd.xdc`의 실제 연결은 다음과 같습니다.

| 신호 | FPGA 핀 | 연결 |
| --- | --- | --- |
| `clk_40m` | L2 | Pmod96 onboard 40 MHz oscillator |
| `txd` | F8 | FPGA TXD → Pmod USBUART RXD |
| `rxd` | F7 | Pmod USBUART TXD → FPGA RXD |

`clk_40m`은 LVCMOS12, UART `rxd/txd`는 LVCMOS18로 설정되어 있습니다.

## 참고

Vivado 버전이나 로컬 board store 경로가 다르면 프로젝트를 처음 열 때 board part/IP upgrade 경고가 나올 수 있습니다. Ultra96-V2 board files를 설치하고, 필요하면 Clocking Wizard output products를 현재 Vivado 버전에서 다시 생성하면 됩니다.
