# 1주차 — C 언어와 MobileNetV2

파일 수정 날짜와 기능적 연관성을 기준으로 C 기초부터 MobileNetV2 전체 네트워크 구현까지 여섯 단계로 묶었습니다.

| 순서 | 디렉터리 | 날짜 | 내용 |
| --- | --- | --- | --- |
| 01 | [`01-c-basics`](01-c-basics/) | 6월 22~23일 | C 문법, 배열, 반복문, 함수 |
| 02 | [`02-convolution-and-pooling`](02-convolution-and-pooling/) | 6월 23일 | 1D/2D convolution과 pooling |
| 03 | [`03-pointers-and-image-convolution`](03-pointers-and-image-convolution/) | 6월 24일 | 포인터/함수 기반 convolution과 RAW 영상 처리 |
| 04 | [`04-bitmap-processing`](04-bitmap-processing/) | 6월 25일 | BMP 복사, RGB 채널, 상하/좌우 반전 |
| 05 | [`05-mobilenetv2-layer08`](05-mobilenetv2-layer08/) | 6월 25~26일 | MobileNetV2 파라미터와 Layer 8 pointwise convolution |
| 06 | [`06-mobilenetv2-complete`](06-mobilenetv2-complete/) | — | MobileNetV2 전체 네트워크 C 구현 |

## 01. C 기초

- `test.c`, `test2.c` — 기본 입출력과 문법
- `9x9.c`, `star_printing.c` — 중첩 반복문
- `functions.c` — 함수 분리 연습

## 02. Convolution과 Pooling

- `conv.c` — 기본 convolution
- `2D_conv.c`, `10x10_2D_conv.c` — 2차원 convolution 확장
- `pooling.c` — pooling 연산

## 03. 포인터와 영상 Convolution

`conv_pointer.c`에서 포인터를 적용하고 `conv_pointer_func.c`에서 함수로 구조화한 뒤, `conv_image.c`에서 RAW 영상 입출력으로 확장합니다. 입력·출력 데이터도 같은 디렉터리에 배치했습니다.

## 04. Bitmap 처리

공통 헤더 `bitmap.h`, 네 가지 BMP 처리 소스, 입력 영상과 생성 결과를 한곳에 묶었습니다.

## 05. MobileNetV2 Layer 8

`Layer08.c`와 계층 사양, 파라미터, 입력/기준 출력 바이너리를 함께 배치했습니다. `mobilenetv2_parameters.h`는 약 35.5 MiB이지만 실습 재현에 필요해 포함했습니다.

## 06. MobileNetV2 완성본

`C/`에는 전체 MobileNetV2 추론을 수행하는 소스와 계층별 기준 입출력 바이너리를 배치했습니다. `C/tools/make_input_bin.py`로 일반 이미지를 224×224 CHW float32 입력 BIN으로 변환할 수 있고, 직접 변환·추론한 기타 및 고양이 자료는 `C/samples/`에 종류별로 정리했습니다.

Layer 8 고정소수점 Golden 모델과 Verilog 구현은 6주차의 [`03-mobilenetv2-pointwise`](../week06-memory-and-dsp/03-mobilenetv2-pointwise/)로 분리했습니다. 이 디렉터리는 전체 네트워크 C 구현만 보관합니다.

컴파일된 `.exe` 파일은 제외했으므로 사용 환경의 C 컴파일러로 다시 빌드하세요.
