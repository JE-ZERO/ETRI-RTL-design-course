# 1주차 — C 언어와 MobileNetV2

RTL 설계에 앞서 C 언어로 데이터 처리와 신경망 연산을 구현한 실습입니다.

## 학습 흐름

1. `test.c`, `test2.c`, `9x9.c`, `star_printing.c`, `functions.c` — C 문법과 함수
2. `conv.c`, `2D_conv.c`, `10x10_2D_conv.c` — 1D/2D convolution
3. `conv_pointer.c`, `conv_pointer_func.c` — 포인터와 함수로 convolution 구조화
4. `pooling.c` — pooling 연산
5. `bitmap_*.c`, `conv_image.c` — BMP 읽기/쓰기와 영상 convolution
6. `Layer08.c` — MobileNetV2 Layer 8 pointwise convolution 구현

## 주요 데이터

- `mobilenetv2_parameters.h` — MobileNetV2 가중치와 파라미터
- `mobilenetv2_result_layer07.bin` — Layer 7 기준 입력/결과 데이터
- `random_layer07_input.bin`, `random_pointwise_out.bin` — 임의 입력 검증 데이터
- `*.bmp`, `*.raw` — 영상 처리 입출력 예제

컴파일된 `.exe` 파일은 저장소에서 제외했습니다. 사용 환경의 C 컴파일러로 각 소스를 다시 빌드하세요.

