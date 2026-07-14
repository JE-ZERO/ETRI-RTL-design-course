# 4주차 — AXI4-Lite와 UART

AXI4-Lite 프로토콜을 사용하는 메모리 및 UART 주변장치를 구현하고 ZedBoard에 연결한 실습입니다.

## 프로젝트 흐름

1. `amba_axi_lite_mem_simple` — AXI4-Lite 메모리 슬레이브
2. `axi4_to_lite` — AXI4 트랜잭션을 단순화하는 변환기와 동기 FIFO
3. `ex_uart` — UART 관련 기초 예제
4. `uart_axi_lite` — UART TX/RX, FIFO, CSR, AXI4-Lite 인터페이스 통합
5. `uart_axi_lite_zedboard` — ZedBoard 하드웨어 구성과 ARM UART 테스트

`uart_axi_lite`의 핵심 RTL은 `rtl/verilog`, SystemVerilog 테스트벤치와 AXI/UART 태스크는 `bench/verilog`, 레지스터 접근용 C API는 `api/c`에 있습니다.

ZedBoard 프로젝트는 `hw/impl.zed/design_zed.tcl`로 재생성할 수 있으며 소프트웨어 예제는 `sw.arm/uart_test/src`에 있습니다.
