# Layer 8 Pointwise Golden Model

이미 signed 16비트 고정소수점으로 준비된 입력과 가중치를 사용하는 단순 bit-true C 모델입니다. Float 양자화, Batch Normalization, ReLU6와 출력 재양자화는 포함하지 않습니다.

| 데이터 | 형식 | 배열 순서 |
| --- | --- | --- |
| 입력 | signed 16-bit, F11 | CHW `[64][14][14]` |
| 가중치 | signed 16-bit, F13 | `[384][64]` |
| 누산 결과 | signed 48-bit, F24 | CHW `[384][14][14]` |

입력과 가중치의 소수부 합이 24비트이므로 곱셈 결과와 누산 결과는 F24입니다. C에서는 64비트 정수로 계산한 뒤 signed 48비트 범위를 확인하고, 한 줄에 12자리 2의 보수 16진수로 출력합니다.

Visual Studio Developer PowerShell 실행 예시는 다음과 같습니다.

```powershell
cl /nologo /W4 /O2 /TC layer8_pointwise_golden.c
./layer8_pointwise_golden.exe `
  ../generated/layer8_input_q16.bin `
  ../generated/layer8_weight_q16.bin `
  ../generated/layer8_pointwise_acc_simple.mem
```

생성 결과는 baseline과 OS32 테스트벤치에서 공통으로 사용합니다. 병렬 구조는 계산 순서와 출력 순서만 달라질 뿐 동일한 수식과 비트폭을 사용하므로 Golden 모델을 별도로 변경할 필요가 없습니다.
