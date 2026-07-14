#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "Layer_Spec.h"
#include "mobilenetv2_parameters.h"


void pointwise_conv_1x1(const float *input, const float *weight, float *output, int in_ch, int out_ch, int height, int width);
void batch_normalizaiton(float *data, int ch_num, int height, int width, const float *mean, const float *var, const float *gamma, const float *beta);


int main()
{
    float *layer8_in_buf=(float*)malloc(LAYER8_IN_SIZE*sizeof(float));//Layer8 입력 크기만큼 동적할당
    float *expand_out_buf=(float*)calloc(LAYER8_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer8_in_buf == NULL || expand_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        return 1;
    }

    FILE *fpIn=fopen("random_layer07_input.bin", "rb");//입력 스트림 생성(포인터와 연결)


    if(fpIn == NULL)//파일 읽기 실패 예외처리
    {
        printf("Not available to open file\n");
        return 1;
    }


    size_t read_count = fread(layer8_in_buf, sizeof(float), LAYER8_IN_SIZE, fpIn);//Layer 8 입력 크기만큼 읽어서 버퍼에 저장

    if(read_count != LAYER8_IN_SIZE)//제대로 안읽힌 경우 예외처리
    {
        printf("File read error\n");
        return 1;
    }


    //pointwise convolution 함수 호출
    pointwise_conv_1x1(layer8_in_buf, features_8_conv_0_0_weight, expand_out_buf, LAYER8_IN_C, LAYER8_EXP_C, LAYER8_IN_H, LAYER8_IN_W);


    //출력 스트림 생성(포인터와 연결)
    FILE *fpOut = fopen("random_pointwise_out.bin", "wb");

    if(fpOut == NULL)//출력 파일 생성 실패 예외처리
    {
        printf("Not available to write file\n");
        fclose(fpIn);
        free(layer8_in_buf);
        free(expand_out_buf);
        return 1;
    }

    fwrite(expand_out_buf, sizeof(float), LAYER8_EXP_SIZE, fpOut);//출력 버퍼에 있는 내용을 파일로 쓰기

    fclose(fpIn);//입력 스트림 소멸
    fclose(fpOut);//출력 스트림 소멸
    free(layer8_in_buf);//입력버퍼 할당 해제
    free(expand_out_buf);//출력버퍼 할당 해제
    

    return 0;
}





void pointwise_conv_1x1(const float *input, const float *weight, float *output, int in_ch, int out_ch, int height, int width)
{
    int out_ch_idx, in_ch_idx, row, col;

    for(out_ch_idx=0; out_ch_idx<out_ch; out_ch_idx++)
    {
        for(row=0; row<height; row++)
        {
            for(col=0; col<width; col++)
            {
                for(in_ch_idx=0; in_ch_idx<in_ch; in_ch_idx++)
                {
                    output[out_ch_idx * height * width + row * width + col] +=
                    input[in_ch_idx * height * width + row * width + col] * weight[out_ch_idx * in_ch + in_ch_idx];
                }
            }
        }
    }

    return;
}


void batch_normalizaiton(float *data, int ch_num, int height, int width, const float *mean, const float *var, const float *gamma, const float *beta)
{
    int ch_idx, row, col;

    for(ch_idx=0; ch_idx<ch_num; ch_idx++)
    {
        for(row=0; row<height; row++)
        {
            for(col=0; col<width; col++)
            {
                data[ch_idx * height * width + row * width + col] =
                gamma[ch_idx] * (data[ch_idx * height * width + row * width + col] - mean[ch_idx]) / sqrt(var[ch_idx] + EPSILON) + beta[ch_idx];
            }
        }
    }
}