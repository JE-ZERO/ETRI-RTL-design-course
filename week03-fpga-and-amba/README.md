# 3주차 — FPGA와 AMBA 버스

디렉터리 이름을 학습 순서대로 통일하고, 서로 참조하는 RTL IP·Block Design·ARM 소프트웨어는 하나의 시스템 챕터로 묶었습니다.

## 개발 환경

- 개발 도구: Xilinx Vivado 2020.2, Xilinx Vitis 2020.2
- FPGA 보드: ZedBoard

| 순서 | 디렉터리 | 내용 |
| --- | --- | --- |
| 01 | [`01-memory-basics`](01-memory-basics/) | 기본 메모리 RTL과 테스트벤치 |
| 02 | [`02-memory-byte-enable`](02-memory-byte-enable/) | 부분 쓰기/byte enable 메모리 |
| 03 | [`03-amba-ahb-practice`](03-amba-ahb-practice/) | AMBA AHB 버스 및 BFM 실습 |
| 04 | [`04-apb-memory-peripheral`](04-apb-memory-peripheral/) | APB 메모리 주변장치 |
| 05 | [`05-zedboard-apb-system`](05-zedboard-apb-system/) | AXI-to-APB, 메모리/GPIO IP, ZedBoard BD와 ARM 소프트웨어 |

## 공통 프로젝트 구조

- `rtl/verilog` — 합성 대상 RTL
- `bench/verilog` — 테스트벤치와 버스 태스크
- `sim`, `sim.gate` — RTL/게이트 시뮬레이션 스크립트
- `syn` — Vivado 합성 스크립트
- `api/c` — 주변장치 접근용 C API

## 05. ZedBoard APB 시스템

마지막 챕터는 BD가 실제로 참조하는 소스를 기준으로 다음처럼 구성했습니다.

```text
05-zedboard-apb-system/
├── ip/
│   ├── axi4-to-apb-and-memory/   # 브리지와 APB 메모리 RTL
│   └── gpio-apb/                 # GPIO RTL, 테스트벤치, C API
└── examples/
    ├── 01-memory-only/           # 메모리 BD + hello_world SW
    └── 02-memory-and-gpio/       # 메모리/GPIO BD + gpio_test SW
```

각 예제의 `hw/impl.zed/design_zed.tcl`은 같은 챕터의 `ip` 소스를 참조하도록 경로를 갱신했습니다. `RunVivado.bat` 또는 `make`로 BD 프로젝트를 재생성할 수 있으며 ARM 코드는 `sw.arm/<application>/src`에 있습니다.
