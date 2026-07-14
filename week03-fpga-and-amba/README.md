# 3주차 — FPGA와 AMBA 버스

메모리 RTL을 시작으로 AMBA AHB/APB 주변장치를 설계하고 ZedBoard의 ARM 프로세서와 연결한 실습입니다.

## 프로젝트 흐름

1. `ex_memory` — 기본 메모리 RTL과 테스트벤치
2. `ex_memory_partial` — 부분 쓰기를 지원하는 메모리
3. `ex_AHB` — AHB 기반 버스 실습
4. `ex_mem_apb` — APB 메모리 주변장치
5. `ex_ARM_mem_apb` — AXI-to-APB 브리지와 메모리 연동
6. `ex_gpio_apb` — APB GPIO RTL 및 C API
7. `ex_mem_apb_zedboard` — ZedBoard 메모리 주변장치 연동
8. `S04_ex_gpio_apb_zedboard` — ZedBoard GPIO 주변장치와 소프트웨어 테스트

일반 RTL 프로젝트는 `rtl/verilog`, 테스트벤치는 `bench/verilog`, 시뮬레이션 및 합성 스크립트는 각각 `sim`, `syn`에서 확인할 수 있습니다.

ZedBoard 프로젝트는 `hw/impl.zed/design_zed.tcl`로 하드웨어 구성을 재생성하고, `sw.arm/*/src`에서 ARM 테스트 코드를 확인할 수 있습니다.

