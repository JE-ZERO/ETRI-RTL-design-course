# ETRI RTL Design Course

ETRI RTL 설계 교육에서 진행한 실습을 주차별로 정리한 저장소입니다. C 언어로 합성곱과 MobileNetV2 연산을 구현하는 과정에서 시작해 Verilog RTL 설계, FPGA/Zynq 시스템 구성, AMBA AXI4-Lite 주변장치 설계까지 이어집니다.

## 주차별 구성

| 주차 | 주제 | 주요 내용 |
| --- | --- | --- |
| [1주차](week01-c-mobilenetv2/) | C 언어와 MobileNetV2 | 날짜·기능별 5개 소챕터: C 기초, convolution, 영상/BMP, MobileNetV2 Layer 8 |
| [2주차](week02-verilog-basics/) | Verilog 기본 | 조합·순차논리, 카운터, FSM, 시계/타이머, UART 기초 |
| [3주차](week03-fpga-and-amba/) | FPGA와 AMBA 버스 | 번호순 메모리/AHB/APB 실습과 RTL-BD-SW 통합 ZedBoard 시스템 |
| [4주차](week04-axi/) | AXI4-Lite와 UART | AXI4-Lite 메모리와 변환기-UART-BD-SW 통합 시스템 |

## 저장소 관리 기준

- 직접 작성하거나 실습에 필요한 C/RTL/테스트벤치/API/TCL/XDC 파일을 보존했습니다.
- `mobilenetv2_parameters.h`는 MobileNetV2 실습 재현을 위해 포함했습니다.
- 실행 파일, Vivado/Vitis 캐시, 합성 체크포인트, 비트스트림, 로그와 시뮬레이션 파형은 제외했습니다.
- 각 프로젝트의 `Clean.bat` 또는 `Clean.sh`로 생성물을 정리할 수 있습니다.
- ZedBoard 하드웨어 프로젝트는 `hw/impl.zed/design_zed.tcl`과 실행 스크립트로 다시 생성하도록 구성했습니다.
- BD가 참조하는 RTL IP와 대응 ARM 소프트웨어는 같은 시스템 챕터 안에 배치했습니다.

## 사용 환경

- C 실습: GCC 또는 호환 C 컴파일러
- RTL 시뮬레이션/합성: Xilinx Vivado
- ZedBoard 소프트웨어: Xilinx Vitis 또는 SDK
- 일부 프로젝트는 Windows 배치 파일과 Unix 셸 스크립트를 함께 제공합니다.

> 프로젝트별 세부 내용은 각 주차 디렉터리의 README를 참고하세요.
