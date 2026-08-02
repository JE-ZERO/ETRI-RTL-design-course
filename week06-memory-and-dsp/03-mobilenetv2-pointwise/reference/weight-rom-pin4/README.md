# Pin=4 Weight ROM 초기 검토 자료

현재 OS32 구현 전에 입력 채널 가중치 4개를 한 word로 묶는 방식을 검토한 자료입니다.

| 항목 | 값 |
| --- | ---: |
| ROM word | 64-bit, signed 16-bit weight 4개 |
| depth | 6,144 |
| 주소 | `out_channel × 16 + in_channel_group` |
| 용도 | packing과 ROM 주소 검증 |

`generate_layer8_expansion_test_weight_coe.ps1`은 -8부터 7까지의 결정론적 시험값을 생성하며, 실제 학습 가중치가 아닙니다. 현재 OS32 구현은 이 자료 대신 `blk_mem_gen_2`와 512비트 packed weight COE를 사용합니다.
