# 4주차 — AXI4-Lite와 UART

AXI4-Lite 메모리에서 UART 주변장치와 ZedBoard 통합 시스템으로 진행됩니다. 최종 BD가 참조하는 변환기·UART IP·ARM 소프트웨어를 하나의 챕터로 묶었습니다.

## 개발 환경

- 개발 도구: Xilinx Vivado 2020.2, Xilinx Vitis 2020.2
- FPGA 보드: ZedBoard

| 순서 | 디렉터리 | 내용 |
| --- | --- | --- |
| 01 | [`01-axi-lite-memory`](01-axi-lite-memory/) | AXI4-Lite 메모리 슬레이브 |
| 02 | [`02-uart-transmitter`](02-uart-transmitter/) | UART 송신기 기초와 AXI 태스크 실습 |
| 03 | [`03-axi-lite-uart-system`](03-axi-lite-uart-system/) | AXI 변환기, UART IP, ZedBoard BD와 ARM 테스트 |

## 03. AXI4-Lite UART 시스템

```text
03-axi-lite-uart-system/
├── ip/
│   ├── axi4-to-lite/             # AXI 변환기와 동기 FIFO
│   └── uart-axi-lite/            # UART TX/RX, FIFO, CSR, AXI 인터페이스
└── zedboard/
    ├── hw/impl.zed/              # BD 생성 Tcl과 XDC
    └── sw.arm/uart_test/         # ARM UART 테스트 소프트웨어
```

`zedboard/hw/impl.zed/design_zed.tcl`은 같은 챕터의 두 IP를 직접 참조하도록 수정했습니다. UART 단독 RTL/시뮬레이션/API는 `ip/uart-axi-lite`에서 확인할 수 있습니다.
