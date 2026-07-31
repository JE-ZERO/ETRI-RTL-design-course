# 6주차 — 메모리와 DSP IP

Vivado에서 여러 형태의 메모리를 RTL과 Block Memory Generator IP로 구현하고, 곱셈기 IP의 결과를 BRAM에 저장하는 실습입니다.

| 디렉터리 | 주요 내용 |
| --- | --- |
| [`block_mem`](block_mem/) | Single-port RAM/ROM, simple·true dual-port RAM, BRAM 초기화와 메모리 간 데이터 복사 |
| [`DSP`](DSP/) | Multiplier Generator와 Block Memory Generator를 연결한 9×9 곱셈 결과 저장 |

## Block Memory 실습

- `single_port_RAM.v`, `single_port_ROM.v` — 단일 포트 메모리
- `simple_dual_port_RAM.v`, `true_dual_port_RAM.v` — 듀얼 포트 메모리
- `memory_copy.v` — 한 메모리의 데이터를 다른 메모리로 복사하는 제어 로직
- `bram_init.coe` — Block Memory Generator 초기화 데이터
- 각 설계에 대응하는 SystemVerilog/Verilog 테스트벤치

Vivado 프로젝트는 [`block_mem/block_mem.xpr`](block_mem/block_mem.xpr)에서 열 수 있습니다.

## DSP 실습

`Mult_9x9.v`는 Multiplier Generator IP로 9비트 입력 두 개를 곱하고, 결과를 Block Memory Generator IP에 저장합니다. `tb_Mult_9x9.sv`에서 동작을 검증할 수 있습니다.

Vivado 프로젝트는 [`DSP/DSP.xpr`](DSP/DSP.xpr)에서 열 수 있습니다.

## 개발 환경

- Xilinx Vivado 2020.2
- Ultra96-V2 (`xczu3eg-sbva484-1-e`)

Vivado 캐시, 합성 결과, 시뮬레이션 출력과 비트스트림은 저장소의 `.gitignore` 정책에 따라 제외했습니다.
