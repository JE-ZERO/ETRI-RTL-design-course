# AXI4-Lite UART System

AXI 인터페이스 변환기와 UART 주변장치 RTL, 이를 사용하는 ZedBoard Block Design 및 ARM 테스트 코드를 한 실습 단위로 묶었습니다.

- `ip/axi4-to-lite` — AXI4 요청을 단순 인터페이스로 변환
- `ip/uart-axi-lite` — UART core, CSR, FIFO, AXI4-Lite 인터페이스와 테스트벤치
- `zedboard/hw/impl.zed` — Vivado BD 생성 스크립트와 핀 제약
- `zedboard/sw.arm/uart_test` — ARM에서 UART 레지스터를 제어하는 예제
