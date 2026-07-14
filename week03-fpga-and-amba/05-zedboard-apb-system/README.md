# ZedBoard APB System

AXI4 master인 Zynq Processing System에서 APB 메모리와 GPIO 주변장치로 접근하는 실습 묶음입니다.

- `ip/axi4-to-apb-and-memory` — AXI4-to-APB 브리지와 APB 메모리
- `ip/gpio-apb` — APB GPIO와 레지스터 접근 API
- `examples/01-memory-only` — 메모리 전용 Block Design과 ARM 예제
- `examples/02-memory-and-gpio` — 메모리/GPIO Block Design과 ARM 예제

BD 생성 스크립트와 대응하는 소프트웨어가 각 `examples` 디렉터리 안에서 한 쌍을 이룹니다.
