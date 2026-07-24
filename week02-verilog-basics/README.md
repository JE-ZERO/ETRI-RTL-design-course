# 2주차 — Verilog 기본

Vivado에서 조합논리, 순차논리, FSM과 간단한 주변장치를 구현한 실습입니다. 생성된 캐시와 합성 결과 대신 RTL 및 제약 파일만 보존했습니다.

## 개발 환경

- 개발 도구: Xilinx Vivado 2020.2, Xilinx Vitis 2020.2
- FPGA 보드: Ultra96

## 프로젝트

- `project_1` — adder, mux, multiplier, counter, flip-flop 등 기본 RTL
- `FSMpractice` — 유한상태기계 설계 연습
- `clock` — 시계 회로
- `digital_timer` — 제어기, 시간 설정, 표시 출력이 포함된 디지털 타이머
- `UART` — PMOD UART 기초 실습
- `ex_memory`, `week3_practice` — 다음 주차로 이어지는 메모리/응용 예제

각 프로젝트 아래의 `*.v`, `*.sv`, `*.xdc` 파일을 새 Vivado 프로젝트에 추가해 사용할 수 있습니다.

