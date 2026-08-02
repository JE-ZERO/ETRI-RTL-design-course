#define _CRT_SECURE_NO_WARNINGS

/*
 * MobileNetV2 Layer8 포인트와이즈 비트 단위 검증 모델
 *
 * 입력   : 부호 있는 16비트, F=11, CHW [64][14][14]
 * 가중치 : 부호 있는 16비트, F=13,     [384][64]
 * 출력   : 부호 있는 48비트, F=24,     CHW [384][14][14]
 *
 * 양자화와 배치 정규화 미포함
 */

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define HEIGHT 14
#define WIDTH 14
#define IN_CHANNELS 64
#define OUT_CHANNELS 384
#define PIXELS (HEIGHT * WIDTH)
#define INPUT_COUNT (IN_CHANNELS * PIXELS)
#define WEIGHT_COUNT (OUT_CHANNELS * IN_CHANNELS)

#define INPUT_FRAC_BITS 11
#define WEIGHT_FRAC_BITS 13
#define ACC_FRAC_BITS (INPUT_FRAC_BITS + WEIGHT_FRAC_BITS)

static int16_t input_data[INPUT_COUNT];
static int16_t weight_data[WEIGHT_COUNT];

// 부호 있는 16비트 이진 파일 읽기
static int read_int16_file(const char *file_name, int16_t *data, size_t count)
{
    FILE *file;
    size_t read_count;
    int extra_byte;

    file = fopen(file_name, "rb");
    if (file == NULL) {
        printf("Cannot open %s\n", file_name);
        return 0;
    }

    read_count = fread(data, sizeof(int16_t), count, file);
    extra_byte = fgetc(file);
    fclose(file);

    if (read_count != count || extra_byte != EOF) {
        printf("Wrong file size: %s\n", file_name);
        return 0;
    }

    return 1;
}

// 부호 있는 48비트 범위 확인
static int is_signed_48bit(int64_t value)
{
    const int64_t minimum = -(INT64_C(1) << 47);
    const int64_t maximum = (INT64_C(1) << 47) - 1;
    return value >= minimum && value <= maximum;
}

int main(int argc, char *argv[])
{
    FILE *output_file;
    int out_channel;
    int pixel;
    int in_channel;

    if (argc != 4) {
        printf("Usage: %s input_q16.bin weight_q16.bin output_acc.mem\n",
               argv[0]);
        return 1;
    }

    if (!read_int16_file(argv[1], input_data, INPUT_COUNT))
        return 1;
    if (!read_int16_file(argv[2], weight_data, WEIGHT_COUNT))
        return 1;

    output_file = fopen(argv[3], "w");
    if (output_file == NULL) {
        printf("Cannot create %s\n", argv[3]);
        return 1;
    }

    // 출력 채널, 픽셀, 입력 채널 순서로 MAC 수행
    for (out_channel = 0; out_channel < OUT_CHANNELS; out_channel++) {
        for (pixel = 0; pixel < PIXELS; pixel++) {
            int64_t accumulator = 0;

            for (in_channel = 0; in_channel < IN_CHANNELS; in_channel++) {
                int input_index = in_channel * PIXELS + pixel;
                int weight_index = out_channel * IN_CHANNELS + in_channel;

                accumulator +=
                    (int32_t)input_data[input_index] *
                    (int32_t)weight_data[weight_index];
            }

            if (!is_signed_48bit(accumulator)) {
                printf("48-bit overflow at output channel %d, pixel %d\n",
                       out_channel, pixel);
                fclose(output_file);
                return 1;
            }

            fprintf(output_file, "%012" PRIX64 "\n",
                    (uint64_t)accumulator & UINT64_C(0xFFFFFFFFFFFF));
        }
    }

    fclose(output_file);

    printf("Done: %d outputs, %d MACs\n",
           OUT_CHANNELS * PIXELS,
           OUT_CHANNELS * PIXELS * IN_CHANNELS);
    printf("Output format: signed 48-bit, F=%d\n", ACC_FRAC_BITS);

    return 0;
}
