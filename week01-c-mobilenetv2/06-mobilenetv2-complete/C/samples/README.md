# MobileNetV2 custom image samples

직접 준비한 이미지를 `tools/make_input_bin.py`로 변환한 입력과, 전체 MobileNetV2 C 구현으로 생성한 출력이 있는 경우 그 결과를 함께 보관합니다.

## 입력 BIN 형식

변환 도구는 이미지를 RGB 224×224로 resize하고, 각 채널을 `[0, 1]` 범위의 `float32`로 정규화한 뒤 CHW 순서 `(3, 224, 224)`로 저장합니다. 따라서 입력 BIN 하나의 크기는 602,112 bytes입니다.

```powershell
python tools/make_input_bin.py input.jpg output224_input.bin
```

## 샘플 구성

| 디렉터리 | 원본 이미지 | 입력 BIN | 출력 BIN |
| --- | --- | --- | --- |
| `acoustic_guitar/` | JPG | 있음 | 있음 |
| `electric_guitar/` | PNG | 있음 | 있음 |
| `egyptian_cat/` | JPG | 있음 | 없음 |
| `tabby/` | JPG | 있음 | 있음 |
| `tiger_cat/` | JPG | 있음 | 없음 |

출력 BIN은 1,000개 `float32` 분류 점수로 구성되어 4,000 bytes입니다. 기존 dog 입력과 출력은 각각 `../bin/dog224_input.bin`, `../bin/dog_output.bin`에 있습니다.
