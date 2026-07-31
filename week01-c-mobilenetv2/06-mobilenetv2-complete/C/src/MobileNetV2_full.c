#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "Layer_Spec.h"//직접 만든 Layer별 Spec이 담긴 헤더파일
#include "mobilenetv2_parameters.h"//주어진 파라미터 헤더파일
#include "imagenet_classes.h"//ImageNet class 이름이 담긴 헤더파일



void conv2d_3x3(const float *input, const float *weight, float *output, int in_ch, int out_ch, int in_height, int in_width, int out_height, int out_width, int stride, int padding);
void pointwise_conv_1x1(const float *input, const float *weight, float *output, int in_ch, int out_ch, int height, int width);
void batch_normalization(float *data, int ch_num, int height, int width, const float *mean, const float *var, const float *gamma, const float *beta);
void relu6(float *data, int size);
void depthwise_conv(const float *input, const float *weight, float *output, int ch_num, int in_height, int in_width, int out_height, int out_width, int stride, int padding);
void skip_connection(const float *input, float *output, int size);
void avgpool_7x7(const float *input, float *output, int ch_num, int height, int width);
void add_bias(float *data, const float *bias, int size);
void softmax(const float *input, float *output, int size);
void print_top5_result(const float *data, int size);


int main()
{
    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer00 시작

    float *layer0_in_buf=(float*)malloc(LAYER0_IN_SIZE*sizeof(float));//Layer0 입력 크기만큼 동적할당
    float *layer0_out_buf=(float*)calloc(LAYER0_OUT_SIZE, sizeof(float));//Layer0 출력 크기만큼 동적할당(0으로 초기화)

    if(layer0_in_buf == NULL || layer0_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer0_in_buf);
        free(layer0_out_buf);
        return 1;
    }

    FILE *fpIn=fopen("dog224_input.bin", "rb");//입력 스트림 생성(포인터와 연결)

    if(fpIn == NULL)//파일 읽기 실패 예외처리
    {
        printf("Not available to open file\n");
        free(layer0_in_buf);
        free(layer0_out_buf);
        return 1;
    }

    size_t read_count = fread(layer0_in_buf, sizeof(float), LAYER0_IN_SIZE, fpIn);//Layer0 입력 크기만큼 읽어서 버퍼에 저장

    if(read_count != LAYER0_IN_SIZE)//제대로 안읽힌 경우 예외처리
    {
        printf("File read error\n");
        fclose(fpIn);
        free(layer0_in_buf);
        free(layer0_out_buf);
        return 1;
    }

    fclose(fpIn);//입력 파일은 다 읽었으므로 바로 닫기

    //conv2d 함수 호출 (3 -> 32, stride 2)
    conv2d_3x3(layer0_in_buf, features_0_0_weight, layer0_out_buf, LAYER0_IN_C, LAYER0_OUT_C,
               LAYER0_IN_H, LAYER0_IN_W, LAYER0_OUT_H, LAYER0_OUT_W, LAYER0_STRIDE, LAYER0_PADDING);

    //Layer0 입력은 conv2d 이후 필요없으므로 해제
    free(layer0_in_buf);

    //batch normalization 함수 호출
    batch_normalization(layer0_out_buf, LAYER0_OUT_C, LAYER0_OUT_H, LAYER0_OUT_W, features_0_1_running_mean, features_0_1_running_var, features_0_1_weight, features_0_1_bias);

    //relu6 함수 호출
    relu6(layer0_out_buf, LAYER0_OUT_SIZE);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer01 시작

    float *layer1_depthwise_buf = (float*)calloc(LAYER1_DW_OUT_SIZE, sizeof(float));//depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)

    if(layer1_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer0_out_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer0_out_buf, features_1_conv_0_0_weight, layer1_depthwise_buf, LAYER1_EXP_C,
                   LAYER1_IN_H, LAYER1_IN_W, LAYER1_OUT_H, LAYER1_OUT_W, LAYER1_DW_STRIDE, LAYER1_DW_PADDING);

    //Layer0 출력은 Layer1 depthwise convolution 이후 필요없으므로 해제
    free(layer0_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer1_depthwise_buf, LAYER1_EXP_C, LAYER1_OUT_H, LAYER1_OUT_W, features_1_conv_0_1_running_mean, features_1_conv_0_1_running_var, features_1_conv_0_1_weight, features_1_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer1_depthwise_buf, LAYER1_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer1_out_buf = (float*)calloc(LAYER1_OUT_SIZE, sizeof(float));

    if(layer1_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer1_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (32 -> 16 축소)
    pointwise_conv_1x1(layer1_depthwise_buf, features_1_conv_1_weight, layer1_out_buf, LAYER1_EXP_C, LAYER1_OUT_C, LAYER1_OUT_H, LAYER1_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer1_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer1_out_buf, LAYER1_OUT_C, LAYER1_OUT_H, LAYER1_OUT_W, features_1_conv_2_running_mean, features_1_conv_2_running_var, features_1_conv_2_weight, features_1_conv_2_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer02 시작

    float *layer2_expand_buf=(float*)calloc(LAYER2_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer2_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer1_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (16 -> 96 확장)
    pointwise_conv_1x1(layer1_out_buf, features_2_conv_0_0_weight, layer2_expand_buf, LAYER2_IN_C, LAYER2_EXP_C, LAYER2_IN_H, LAYER2_IN_W);

    //Layer1 출력은 Layer2에서 skip connection 하지 않으므로 해제
    free(layer1_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer2_expand_buf, LAYER2_EXP_C, LAYER2_IN_H, LAYER2_IN_W, features_2_conv_0_1_running_mean, features_2_conv_0_1_running_var, features_2_conv_0_1_weight, features_2_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer2_expand_buf, LAYER2_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer2_depthwise_buf = (float*)calloc(LAYER2_DW_OUT_SIZE, sizeof(float));

    if(layer2_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer2_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer2_expand_buf, features_2_conv_1_0_weight, layer2_depthwise_buf, LAYER2_EXP_C,
                   LAYER2_IN_H, LAYER2_IN_W, LAYER2_OUT_H, LAYER2_OUT_W, LAYER2_DW_STRIDE, LAYER2_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer2_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer2_depthwise_buf, LAYER2_EXP_C, LAYER2_OUT_H, LAYER2_OUT_W, features_2_conv_1_1_running_mean, features_2_conv_1_1_running_var, features_2_conv_1_1_weight, features_2_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer2_depthwise_buf, LAYER2_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer2_out_buf = (float*)calloc(LAYER2_OUT_SIZE, sizeof(float));

    if(layer2_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer2_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (96 -> 24 축소)
    pointwise_conv_1x1(layer2_depthwise_buf, features_2_conv_2_weight, layer2_out_buf, LAYER2_EXP_C, LAYER2_OUT_C, LAYER2_OUT_H, LAYER2_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer2_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer2_out_buf, LAYER2_OUT_C, LAYER2_OUT_H, LAYER2_OUT_W, features_2_conv_3_running_mean, features_2_conv_3_running_var, features_2_conv_3_weight, features_2_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer03 시작

    float *layer3_expand_buf=(float*)calloc(LAYER3_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer3_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer2_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (24 -> 144 확장)
    pointwise_conv_1x1(layer2_out_buf, features_3_conv_0_0_weight, layer3_expand_buf, LAYER3_IN_C, LAYER3_EXP_C, LAYER3_IN_H, LAYER3_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer3_expand_buf, LAYER3_EXP_C, LAYER3_IN_H, LAYER3_IN_W, features_3_conv_0_1_running_mean, features_3_conv_0_1_running_var, features_3_conv_0_1_weight, features_3_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer3_expand_buf, LAYER3_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer3_depthwise_buf = (float*)calloc(LAYER3_DW_OUT_SIZE, sizeof(float));

    if(layer3_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer2_out_buf);
        free(layer3_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer3_expand_buf, features_3_conv_1_0_weight, layer3_depthwise_buf, LAYER3_EXP_C,
                   LAYER3_IN_H, LAYER3_IN_W, LAYER3_OUT_H, LAYER3_OUT_W, LAYER3_DW_STRIDE, LAYER3_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer3_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer3_depthwise_buf, LAYER3_EXP_C, LAYER3_OUT_H, LAYER3_OUT_W, features_3_conv_1_1_running_mean, features_3_conv_1_1_running_var, features_3_conv_1_1_weight, features_3_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer3_depthwise_buf, LAYER3_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer3_out_buf = (float*)calloc(LAYER3_OUT_SIZE, sizeof(float));

    if(layer3_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer2_out_buf);
        free(layer3_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (144 -> 24 축소)
    pointwise_conv_1x1(layer3_depthwise_buf, features_3_conv_2_weight, layer3_out_buf, LAYER3_EXP_C, LAYER3_OUT_C, LAYER3_OUT_H, LAYER3_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer3_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer3_out_buf, LAYER3_OUT_C, LAYER3_OUT_H, LAYER3_OUT_W, features_3_conv_3_running_mean, features_3_conv_3_running_var, features_3_conv_3_weight, features_3_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer2_out_buf, layer3_out_buf, LAYER3_OUT_SIZE);

    //Layer2 출력은 Layer3 skip connection 이후 필요없으므로 해제
    free(layer2_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer04 시작

    float *layer4_expand_buf=(float*)calloc(LAYER4_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer4_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer3_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (24 -> 144 확장)
    pointwise_conv_1x1(layer3_out_buf, features_4_conv_0_0_weight, layer4_expand_buf, LAYER4_IN_C, LAYER4_EXP_C, LAYER4_IN_H, LAYER4_IN_W);

    //Layer3 출력은 Layer4에서 skip connection 하지 않으므로 해제
    free(layer3_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer4_expand_buf, LAYER4_EXP_C, LAYER4_IN_H, LAYER4_IN_W, features_4_conv_0_1_running_mean, features_4_conv_0_1_running_var, features_4_conv_0_1_weight, features_4_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer4_expand_buf, LAYER4_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer4_depthwise_buf = (float*)calloc(LAYER4_DW_OUT_SIZE, sizeof(float));

    if(layer4_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer4_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer4_expand_buf, features_4_conv_1_0_weight, layer4_depthwise_buf, LAYER4_EXP_C,
                   LAYER4_IN_H, LAYER4_IN_W, LAYER4_OUT_H, LAYER4_OUT_W, LAYER4_DW_STRIDE, LAYER4_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer4_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer4_depthwise_buf, LAYER4_EXP_C, LAYER4_OUT_H, LAYER4_OUT_W, features_4_conv_1_1_running_mean, features_4_conv_1_1_running_var, features_4_conv_1_1_weight, features_4_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer4_depthwise_buf, LAYER4_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer4_out_buf = (float*)calloc(LAYER4_OUT_SIZE, sizeof(float));

    if(layer4_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer4_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (144 -> 32 축소)
    pointwise_conv_1x1(layer4_depthwise_buf, features_4_conv_2_weight, layer4_out_buf, LAYER4_EXP_C, LAYER4_OUT_C, LAYER4_OUT_H, LAYER4_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer4_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer4_out_buf, LAYER4_OUT_C, LAYER4_OUT_H, LAYER4_OUT_W, features_4_conv_3_running_mean, features_4_conv_3_running_var, features_4_conv_3_weight, features_4_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer05 시작

    float *layer5_expand_buf=(float*)calloc(LAYER5_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer5_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer4_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (32 -> 192 확장)
    pointwise_conv_1x1(layer4_out_buf, features_5_conv_0_0_weight, layer5_expand_buf, LAYER5_IN_C, LAYER5_EXP_C, LAYER5_IN_H, LAYER5_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer5_expand_buf, LAYER5_EXP_C, LAYER5_IN_H, LAYER5_IN_W, features_5_conv_0_1_running_mean, features_5_conv_0_1_running_var, features_5_conv_0_1_weight, features_5_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer5_expand_buf, LAYER5_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer5_depthwise_buf = (float*)calloc(LAYER5_DW_OUT_SIZE, sizeof(float));

    if(layer5_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer4_out_buf);
        free(layer5_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer5_expand_buf, features_5_conv_1_0_weight, layer5_depthwise_buf, LAYER5_EXP_C,
                   LAYER5_IN_H, LAYER5_IN_W, LAYER5_OUT_H, LAYER5_OUT_W, LAYER5_DW_STRIDE, LAYER5_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer5_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer5_depthwise_buf, LAYER5_EXP_C, LAYER5_OUT_H, LAYER5_OUT_W, features_5_conv_1_1_running_mean, features_5_conv_1_1_running_var, features_5_conv_1_1_weight, features_5_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer5_depthwise_buf, LAYER5_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer5_out_buf = (float*)calloc(LAYER5_OUT_SIZE, sizeof(float));

    if(layer5_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer4_out_buf);
        free(layer5_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (192 -> 32 축소)
    pointwise_conv_1x1(layer5_depthwise_buf, features_5_conv_2_weight, layer5_out_buf, LAYER5_EXP_C, LAYER5_OUT_C, LAYER5_OUT_H, LAYER5_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer5_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer5_out_buf, LAYER5_OUT_C, LAYER5_OUT_H, LAYER5_OUT_W, features_5_conv_3_running_mean, features_5_conv_3_running_var, features_5_conv_3_weight, features_5_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer4_out_buf, layer5_out_buf, LAYER5_OUT_SIZE);

    //Layer4 출력은 Layer5 skip connection 이후 필요없으므로 해제
    free(layer4_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer06 시작

    float *layer6_expand_buf=(float*)calloc(LAYER6_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer6_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer5_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (32 -> 192 확장)
    pointwise_conv_1x1(layer5_out_buf, features_6_conv_0_0_weight, layer6_expand_buf, LAYER6_IN_C, LAYER6_EXP_C, LAYER6_IN_H, LAYER6_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer6_expand_buf, LAYER6_EXP_C, LAYER6_IN_H, LAYER6_IN_W, features_6_conv_0_1_running_mean, features_6_conv_0_1_running_var, features_6_conv_0_1_weight, features_6_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer6_expand_buf, LAYER6_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer6_depthwise_buf = (float*)calloc(LAYER6_DW_OUT_SIZE, sizeof(float));

    if(layer6_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer5_out_buf);
        free(layer6_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer6_expand_buf, features_6_conv_1_0_weight, layer6_depthwise_buf, LAYER6_EXP_C,
                   LAYER6_IN_H, LAYER6_IN_W, LAYER6_OUT_H, LAYER6_OUT_W, LAYER6_DW_STRIDE, LAYER6_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer6_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer6_depthwise_buf, LAYER6_EXP_C, LAYER6_OUT_H, LAYER6_OUT_W, features_6_conv_1_1_running_mean, features_6_conv_1_1_running_var, features_6_conv_1_1_weight, features_6_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer6_depthwise_buf, LAYER6_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer6_out_buf = (float*)calloc(LAYER6_OUT_SIZE, sizeof(float));

    if(layer6_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer5_out_buf);
        free(layer6_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (192 -> 32 축소)
    pointwise_conv_1x1(layer6_depthwise_buf, features_6_conv_2_weight, layer6_out_buf, LAYER6_EXP_C, LAYER6_OUT_C, LAYER6_OUT_H, LAYER6_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer6_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer6_out_buf, LAYER6_OUT_C, LAYER6_OUT_H, LAYER6_OUT_W, features_6_conv_3_running_mean, features_6_conv_3_running_var, features_6_conv_3_weight, features_6_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer5_out_buf, layer6_out_buf, LAYER6_OUT_SIZE);

    //Layer5 출력은 Layer6 skip connection 이후 필요없으므로 해제
    free(layer5_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer07 시작

    float *layer7_expand_buf=(float*)calloc(LAYER7_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer7_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer6_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (32 -> 192 확장)
    pointwise_conv_1x1(layer6_out_buf, features_7_conv_0_0_weight, layer7_expand_buf, LAYER7_IN_C, LAYER7_EXP_C, LAYER7_IN_H, LAYER7_IN_W);

    //Layer6 출력은 Layer7에서 skip connection 하지 않으므로 해제
    free(layer6_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer7_expand_buf, LAYER7_EXP_C, LAYER7_IN_H, LAYER7_IN_W, features_7_conv_0_1_running_mean, features_7_conv_0_1_running_var, features_7_conv_0_1_weight, features_7_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer7_expand_buf, LAYER7_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer7_depthwise_buf = (float*)calloc(LAYER7_DW_OUT_SIZE, sizeof(float));

    if(layer7_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer7_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer7_expand_buf, features_7_conv_1_0_weight, layer7_depthwise_buf, LAYER7_EXP_C,
                   LAYER7_IN_H, LAYER7_IN_W, LAYER7_OUT_H, LAYER7_OUT_W, LAYER7_DW_STRIDE, LAYER7_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer7_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer7_depthwise_buf, LAYER7_EXP_C, LAYER7_OUT_H, LAYER7_OUT_W, features_7_conv_1_1_running_mean, features_7_conv_1_1_running_var, features_7_conv_1_1_weight, features_7_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer7_depthwise_buf, LAYER7_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer7_out_buf = (float*)calloc(LAYER7_OUT_SIZE, sizeof(float));

    if(layer7_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer7_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (192 -> 64 축소)
    pointwise_conv_1x1(layer7_depthwise_buf, features_7_conv_2_weight, layer7_out_buf, LAYER7_EXP_C, LAYER7_OUT_C, LAYER7_OUT_H, LAYER7_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer7_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer7_out_buf, LAYER7_OUT_C, LAYER7_OUT_H, LAYER7_OUT_W, features_7_conv_3_running_mean, features_7_conv_3_running_var, features_7_conv_3_weight, features_7_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer08 시작

    float *layer8_expand_buf=(float*)calloc(LAYER8_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer8_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer7_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (64 -> 384 확장)
    pointwise_conv_1x1(layer7_out_buf, features_8_conv_0_0_weight, layer8_expand_buf, LAYER8_IN_C, LAYER8_EXP_C, LAYER8_IN_H, LAYER8_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer8_expand_buf, LAYER8_EXP_C, LAYER8_IN_H, LAYER8_IN_W, features_8_conv_0_1_running_mean, features_8_conv_0_1_running_var, features_8_conv_0_1_weight, features_8_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer8_expand_buf, LAYER8_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer8_depthwise_buf = (float*)calloc(LAYER8_DW_OUT_SIZE, sizeof(float));

    if(layer8_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer7_out_buf);
        free(layer8_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer8_expand_buf, features_8_conv_1_0_weight, layer8_depthwise_buf, LAYER8_EXP_C,
                   LAYER8_IN_H, LAYER8_IN_W, LAYER8_OUT_H, LAYER8_OUT_W, LAYER8_DW_STRIDE, LAYER8_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer8_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer8_depthwise_buf, LAYER8_EXP_C, LAYER8_OUT_H, LAYER8_OUT_W, features_8_conv_1_1_running_mean, features_8_conv_1_1_running_var, features_8_conv_1_1_weight, features_8_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer8_depthwise_buf, LAYER8_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer8_out_buf = (float*)calloc(LAYER8_OUT_SIZE, sizeof(float));

    if(layer8_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer7_out_buf);
        free(layer8_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (384 -> 64 축소)
    pointwise_conv_1x1(layer8_depthwise_buf, features_8_conv_2_weight, layer8_out_buf, LAYER8_EXP_C, LAYER8_OUT_C, LAYER8_OUT_H, LAYER8_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer8_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer8_out_buf, LAYER8_OUT_C, LAYER8_OUT_H, LAYER8_OUT_W, features_8_conv_3_running_mean, features_8_conv_3_running_var, features_8_conv_3_weight, features_8_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer7_out_buf, layer8_out_buf, LAYER8_OUT_SIZE);

    //Layer7 출력은 Layer8 skip connection 이후 필요없으므로 해제
    free(layer7_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer09 시작

    float *layer9_expand_buf=(float*)calloc(LAYER9_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer9_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer8_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (64 -> 384 확장)
    pointwise_conv_1x1(layer8_out_buf, features_9_conv_0_0_weight, layer9_expand_buf, LAYER9_IN_C, LAYER9_EXP_C, LAYER9_IN_H, LAYER9_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer9_expand_buf, LAYER9_EXP_C, LAYER9_IN_H, LAYER9_IN_W, features_9_conv_0_1_running_mean, features_9_conv_0_1_running_var, features_9_conv_0_1_weight, features_9_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer9_expand_buf, LAYER9_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer9_depthwise_buf = (float*)calloc(LAYER9_DW_OUT_SIZE, sizeof(float));

    if(layer9_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer8_out_buf);
        free(layer9_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer9_expand_buf, features_9_conv_1_0_weight, layer9_depthwise_buf, LAYER9_EXP_C,
                   LAYER9_IN_H, LAYER9_IN_W, LAYER9_OUT_H, LAYER9_OUT_W, LAYER9_DW_STRIDE, LAYER9_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer9_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer9_depthwise_buf, LAYER9_EXP_C, LAYER9_OUT_H, LAYER9_OUT_W, features_9_conv_1_1_running_mean, features_9_conv_1_1_running_var, features_9_conv_1_1_weight, features_9_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer9_depthwise_buf, LAYER9_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer9_out_buf = (float*)calloc(LAYER9_OUT_SIZE, sizeof(float));

    if(layer9_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer8_out_buf);
        free(layer9_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (384 -> 64 축소)
    pointwise_conv_1x1(layer9_depthwise_buf, features_9_conv_2_weight, layer9_out_buf, LAYER9_EXP_C, LAYER9_OUT_C, LAYER9_OUT_H, LAYER9_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer9_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer9_out_buf, LAYER9_OUT_C, LAYER9_OUT_H, LAYER9_OUT_W, features_9_conv_3_running_mean, features_9_conv_3_running_var, features_9_conv_3_weight, features_9_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer8_out_buf, layer9_out_buf, LAYER9_OUT_SIZE);

    //Layer8 출력은 Layer9 skip connection 이후 필요없으므로 해제
    free(layer8_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer10 시작

    float *layer10_expand_buf=(float*)calloc(LAYER10_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer10_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer9_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (64 -> 384 확장)
    pointwise_conv_1x1(layer9_out_buf, features_10_conv_0_0_weight, layer10_expand_buf, LAYER10_IN_C, LAYER10_EXP_C, LAYER10_IN_H, LAYER10_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer10_expand_buf, LAYER10_EXP_C, LAYER10_IN_H, LAYER10_IN_W, features_10_conv_0_1_running_mean, features_10_conv_0_1_running_var, features_10_conv_0_1_weight, features_10_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer10_expand_buf, LAYER10_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer10_depthwise_buf = (float*)calloc(LAYER10_DW_OUT_SIZE, sizeof(float));

    if(layer10_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer9_out_buf);
        free(layer10_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer10_expand_buf, features_10_conv_1_0_weight, layer10_depthwise_buf, LAYER10_EXP_C,
                   LAYER10_IN_H, LAYER10_IN_W, LAYER10_OUT_H, LAYER10_OUT_W, LAYER10_DW_STRIDE, LAYER10_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer10_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer10_depthwise_buf, LAYER10_EXP_C, LAYER10_OUT_H, LAYER10_OUT_W, features_10_conv_1_1_running_mean, features_10_conv_1_1_running_var, features_10_conv_1_1_weight, features_10_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer10_depthwise_buf, LAYER10_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer10_out_buf = (float*)calloc(LAYER10_OUT_SIZE, sizeof(float));

    if(layer10_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer9_out_buf);
        free(layer10_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (384 -> 64 축소)
    pointwise_conv_1x1(layer10_depthwise_buf, features_10_conv_2_weight, layer10_out_buf, LAYER10_EXP_C, LAYER10_OUT_C, LAYER10_OUT_H, LAYER10_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer10_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer10_out_buf, LAYER10_OUT_C, LAYER10_OUT_H, LAYER10_OUT_W, features_10_conv_3_running_mean, features_10_conv_3_running_var, features_10_conv_3_weight, features_10_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer9_out_buf, layer10_out_buf, LAYER10_OUT_SIZE);

    //Layer9 출력은 Layer10 skip connection 이후 필요없으므로 해제
    free(layer9_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer11 시작

    float *layer11_expand_buf=(float*)calloc(LAYER11_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer11_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer10_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (64 -> 384 확장)
    pointwise_conv_1x1(layer10_out_buf, features_11_conv_0_0_weight, layer11_expand_buf, LAYER11_IN_C, LAYER11_EXP_C, LAYER11_IN_H, LAYER11_IN_W);

    //Layer10 출력은 Layer11에서 skip connection 하지 않으므로 해제
    free(layer10_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer11_expand_buf, LAYER11_EXP_C, LAYER11_IN_H, LAYER11_IN_W, features_11_conv_0_1_running_mean, features_11_conv_0_1_running_var, features_11_conv_0_1_weight, features_11_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer11_expand_buf, LAYER11_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer11_depthwise_buf = (float*)calloc(LAYER11_DW_OUT_SIZE, sizeof(float));

    if(layer11_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer11_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer11_expand_buf, features_11_conv_1_0_weight, layer11_depthwise_buf, LAYER11_EXP_C,
                   LAYER11_IN_H, LAYER11_IN_W, LAYER11_OUT_H, LAYER11_OUT_W, LAYER11_DW_STRIDE, LAYER11_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer11_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer11_depthwise_buf, LAYER11_EXP_C, LAYER11_OUT_H, LAYER11_OUT_W, features_11_conv_1_1_running_mean, features_11_conv_1_1_running_var, features_11_conv_1_1_weight, features_11_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer11_depthwise_buf, LAYER11_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer11_out_buf = (float*)calloc(LAYER11_OUT_SIZE, sizeof(float));

    if(layer11_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer11_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (384 -> 96 축소)
    pointwise_conv_1x1(layer11_depthwise_buf, features_11_conv_2_weight, layer11_out_buf, LAYER11_EXP_C, LAYER11_OUT_C, LAYER11_OUT_H, LAYER11_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer11_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer11_out_buf, LAYER11_OUT_C, LAYER11_OUT_H, LAYER11_OUT_W, features_11_conv_3_running_mean, features_11_conv_3_running_var, features_11_conv_3_weight, features_11_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer12 시작

    float *layer12_expand_buf=(float*)calloc(LAYER12_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer12_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer11_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (96 -> 576 확장)
    pointwise_conv_1x1(layer11_out_buf, features_12_conv_0_0_weight, layer12_expand_buf, LAYER12_IN_C, LAYER12_EXP_C, LAYER12_IN_H, LAYER12_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer12_expand_buf, LAYER12_EXP_C, LAYER12_IN_H, LAYER12_IN_W, features_12_conv_0_1_running_mean, features_12_conv_0_1_running_var, features_12_conv_0_1_weight, features_12_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer12_expand_buf, LAYER12_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer12_depthwise_buf = (float*)calloc(LAYER12_DW_OUT_SIZE, sizeof(float));

    if(layer12_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer11_out_buf);
        free(layer12_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer12_expand_buf, features_12_conv_1_0_weight, layer12_depthwise_buf, LAYER12_EXP_C,
                   LAYER12_IN_H, LAYER12_IN_W, LAYER12_OUT_H, LAYER12_OUT_W, LAYER12_DW_STRIDE, LAYER12_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer12_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer12_depthwise_buf, LAYER12_EXP_C, LAYER12_OUT_H, LAYER12_OUT_W, features_12_conv_1_1_running_mean, features_12_conv_1_1_running_var, features_12_conv_1_1_weight, features_12_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer12_depthwise_buf, LAYER12_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer12_out_buf = (float*)calloc(LAYER12_OUT_SIZE, sizeof(float));

    if(layer12_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer11_out_buf);
        free(layer12_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (576 -> 96 축소)
    pointwise_conv_1x1(layer12_depthwise_buf, features_12_conv_2_weight, layer12_out_buf, LAYER12_EXP_C, LAYER12_OUT_C, LAYER12_OUT_H, LAYER12_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer12_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer12_out_buf, LAYER12_OUT_C, LAYER12_OUT_H, LAYER12_OUT_W, features_12_conv_3_running_mean, features_12_conv_3_running_var, features_12_conv_3_weight, features_12_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer11_out_buf, layer12_out_buf, LAYER12_OUT_SIZE);

    //Layer11 출력은 Layer12 skip connection 이후 필요없으므로 해제
    free(layer11_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer13 시작

    float *layer13_expand_buf=(float*)calloc(LAYER13_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer13_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer12_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (96 -> 576 확장)
    pointwise_conv_1x1(layer12_out_buf, features_13_conv_0_0_weight, layer13_expand_buf, LAYER13_IN_C, LAYER13_EXP_C, LAYER13_IN_H, LAYER13_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer13_expand_buf, LAYER13_EXP_C, LAYER13_IN_H, LAYER13_IN_W, features_13_conv_0_1_running_mean, features_13_conv_0_1_running_var, features_13_conv_0_1_weight, features_13_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer13_expand_buf, LAYER13_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer13_depthwise_buf = (float*)calloc(LAYER13_DW_OUT_SIZE, sizeof(float));

    if(layer13_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer12_out_buf);
        free(layer13_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer13_expand_buf, features_13_conv_1_0_weight, layer13_depthwise_buf, LAYER13_EXP_C,
                   LAYER13_IN_H, LAYER13_IN_W, LAYER13_OUT_H, LAYER13_OUT_W, LAYER13_DW_STRIDE, LAYER13_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer13_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer13_depthwise_buf, LAYER13_EXP_C, LAYER13_OUT_H, LAYER13_OUT_W, features_13_conv_1_1_running_mean, features_13_conv_1_1_running_var, features_13_conv_1_1_weight, features_13_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer13_depthwise_buf, LAYER13_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer13_out_buf = (float*)calloc(LAYER13_OUT_SIZE, sizeof(float));

    if(layer13_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer12_out_buf);
        free(layer13_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (576 -> 96 축소)
    pointwise_conv_1x1(layer13_depthwise_buf, features_13_conv_2_weight, layer13_out_buf, LAYER13_EXP_C, LAYER13_OUT_C, LAYER13_OUT_H, LAYER13_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer13_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer13_out_buf, LAYER13_OUT_C, LAYER13_OUT_H, LAYER13_OUT_W, features_13_conv_3_running_mean, features_13_conv_3_running_var, features_13_conv_3_weight, features_13_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer12_out_buf, layer13_out_buf, LAYER13_OUT_SIZE);

    //Layer12 출력은 Layer13 skip connection 이후 필요없으므로 해제
    free(layer12_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer14 시작

    float *layer14_expand_buf=(float*)calloc(LAYER14_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer14_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer13_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (96 -> 576 확장)
    pointwise_conv_1x1(layer13_out_buf, features_14_conv_0_0_weight, layer14_expand_buf, LAYER14_IN_C, LAYER14_EXP_C, LAYER14_IN_H, LAYER14_IN_W);

    //Layer13 출력은 Layer14에서 skip connection 하지 않으므로 해제
    free(layer13_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer14_expand_buf, LAYER14_EXP_C, LAYER14_IN_H, LAYER14_IN_W, features_14_conv_0_1_running_mean, features_14_conv_0_1_running_var, features_14_conv_0_1_weight, features_14_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer14_expand_buf, LAYER14_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer14_depthwise_buf = (float*)calloc(LAYER14_DW_OUT_SIZE, sizeof(float));

    if(layer14_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer14_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer14_expand_buf, features_14_conv_1_0_weight, layer14_depthwise_buf, LAYER14_EXP_C,
                   LAYER14_IN_H, LAYER14_IN_W, LAYER14_OUT_H, LAYER14_OUT_W, LAYER14_DW_STRIDE, LAYER14_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer14_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer14_depthwise_buf, LAYER14_EXP_C, LAYER14_OUT_H, LAYER14_OUT_W, features_14_conv_1_1_running_mean, features_14_conv_1_1_running_var, features_14_conv_1_1_weight, features_14_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer14_depthwise_buf, LAYER14_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer14_out_buf = (float*)calloc(LAYER14_OUT_SIZE, sizeof(float));

    if(layer14_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer14_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (576 -> 160 축소)
    pointwise_conv_1x1(layer14_depthwise_buf, features_14_conv_2_weight, layer14_out_buf, LAYER14_EXP_C, LAYER14_OUT_C, LAYER14_OUT_H, LAYER14_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer14_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer14_out_buf, LAYER14_OUT_C, LAYER14_OUT_H, LAYER14_OUT_W, features_14_conv_3_running_mean, features_14_conv_3_running_var, features_14_conv_3_weight, features_14_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer15 시작

    float *layer15_expand_buf=(float*)calloc(LAYER15_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer15_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer14_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (160 -> 960 확장)
    pointwise_conv_1x1(layer14_out_buf, features_15_conv_0_0_weight, layer15_expand_buf, LAYER15_IN_C, LAYER15_EXP_C, LAYER15_IN_H, LAYER15_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer15_expand_buf, LAYER15_EXP_C, LAYER15_IN_H, LAYER15_IN_W, features_15_conv_0_1_running_mean, features_15_conv_0_1_running_var, features_15_conv_0_1_weight, features_15_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer15_expand_buf, LAYER15_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer15_depthwise_buf = (float*)calloc(LAYER15_DW_OUT_SIZE, sizeof(float));

    if(layer15_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer14_out_buf);
        free(layer15_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer15_expand_buf, features_15_conv_1_0_weight, layer15_depthwise_buf, LAYER15_EXP_C,
                   LAYER15_IN_H, LAYER15_IN_W, LAYER15_OUT_H, LAYER15_OUT_W, LAYER15_DW_STRIDE, LAYER15_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer15_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer15_depthwise_buf, LAYER15_EXP_C, LAYER15_OUT_H, LAYER15_OUT_W, features_15_conv_1_1_running_mean, features_15_conv_1_1_running_var, features_15_conv_1_1_weight, features_15_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer15_depthwise_buf, LAYER15_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer15_out_buf = (float*)calloc(LAYER15_OUT_SIZE, sizeof(float));

    if(layer15_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer14_out_buf);
        free(layer15_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (960 -> 160 축소)
    pointwise_conv_1x1(layer15_depthwise_buf, features_15_conv_2_weight, layer15_out_buf, LAYER15_EXP_C, LAYER15_OUT_C, LAYER15_OUT_H, LAYER15_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer15_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer15_out_buf, LAYER15_OUT_C, LAYER15_OUT_H, LAYER15_OUT_W, features_15_conv_3_running_mean, features_15_conv_3_running_var, features_15_conv_3_weight, features_15_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer14_out_buf, layer15_out_buf, LAYER15_OUT_SIZE);

    //Layer14 출력은 Layer15 skip connection 이후 필요없으므로 해제
    free(layer14_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer16 시작

    float *layer16_expand_buf=(float*)calloc(LAYER16_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer16_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer15_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (160 -> 960 확장)
    pointwise_conv_1x1(layer15_out_buf, features_16_conv_0_0_weight, layer16_expand_buf, LAYER16_IN_C, LAYER16_EXP_C, LAYER16_IN_H, LAYER16_IN_W);

    //batch normalization 함수 호출
    batch_normalization(layer16_expand_buf, LAYER16_EXP_C, LAYER16_IN_H, LAYER16_IN_W, features_16_conv_0_1_running_mean, features_16_conv_0_1_running_var, features_16_conv_0_1_weight, features_16_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer16_expand_buf, LAYER16_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer16_depthwise_buf = (float*)calloc(LAYER16_DW_OUT_SIZE, sizeof(float));

    if(layer16_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer15_out_buf);
        free(layer16_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer16_expand_buf, features_16_conv_1_0_weight, layer16_depthwise_buf, LAYER16_EXP_C,
                   LAYER16_IN_H, LAYER16_IN_W, LAYER16_OUT_H, LAYER16_OUT_W, LAYER16_DW_STRIDE, LAYER16_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer16_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer16_depthwise_buf, LAYER16_EXP_C, LAYER16_OUT_H, LAYER16_OUT_W, features_16_conv_1_1_running_mean, features_16_conv_1_1_running_var, features_16_conv_1_1_weight, features_16_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer16_depthwise_buf, LAYER16_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer16_out_buf = (float*)calloc(LAYER16_OUT_SIZE, sizeof(float));

    if(layer16_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer15_out_buf);
        free(layer16_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (960 -> 160 축소)
    pointwise_conv_1x1(layer16_depthwise_buf, features_16_conv_2_weight, layer16_out_buf, LAYER16_EXP_C, LAYER16_OUT_C, LAYER16_OUT_H, LAYER16_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer16_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer16_out_buf, LAYER16_OUT_C, LAYER16_OUT_H, LAYER16_OUT_W, features_16_conv_3_running_mean, features_16_conv_3_running_var, features_16_conv_3_weight, features_16_conv_3_bias);

    //skip connection 함수 호출
    skip_connection(layer15_out_buf, layer16_out_buf, LAYER16_OUT_SIZE);

    //Layer15 출력은 Layer16 skip connection 이후 필요없으므로 해제
    free(layer15_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer17 시작

    float *layer17_expand_buf=(float*)calloc(LAYER17_EXP_SIZE, sizeof(float));//확장된 출력 크기만큼 동적할당(0으로 초기화)

    if(layer17_expand_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer16_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (160 -> 960 확장)
    pointwise_conv_1x1(layer16_out_buf, features_17_conv_0_0_weight, layer17_expand_buf, LAYER17_IN_C, LAYER17_EXP_C, LAYER17_IN_H, LAYER17_IN_W);

    //Layer16 출력은 Layer17에서 skip connection 하지 않으므로 해제
    free(layer16_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer17_expand_buf, LAYER17_EXP_C, LAYER17_IN_H, LAYER17_IN_W, features_17_conv_0_1_running_mean, features_17_conv_0_1_running_var, features_17_conv_0_1_weight, features_17_conv_0_1_bias);

    //relu6 함수 호출
    relu6(layer17_expand_buf, LAYER17_EXP_SIZE);

    //depthwise convolution 결과 저장을 위한 동적 할당(calloc 이용하여 0으로 초기화)
    float *layer17_depthwise_buf = (float*)calloc(LAYER17_DW_OUT_SIZE, sizeof(float));

    if(layer17_depthwise_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer17_expand_buf);
        return 1;
    }

    //depthwise convolution 함수 호출
    depthwise_conv(layer17_expand_buf, features_17_conv_1_0_weight, layer17_depthwise_buf, LAYER17_EXP_C,
                   LAYER17_IN_H, LAYER17_IN_W, LAYER17_OUT_H, LAYER17_OUT_W, LAYER17_DW_STRIDE, LAYER17_DW_PADDING);

    //이전의 결과는 필요없으므로 해제
    free(layer17_expand_buf);

    //batch normalization 함수 호출
    batch_normalization(layer17_depthwise_buf, LAYER17_EXP_C, LAYER17_OUT_H, LAYER17_OUT_W, features_17_conv_1_1_running_mean, features_17_conv_1_1_running_var, features_17_conv_1_1_weight, features_17_conv_1_1_bias);

    //relu6 함수 호출
    relu6(layer17_depthwise_buf, LAYER17_DW_OUT_SIZE);

    //projection pointwise convolution 이전에 결과 저장할 공간 동적할당(calloc 이용하여 0으로 초기화)
    float *layer17_out_buf = (float*)calloc(LAYER17_OUT_SIZE, sizeof(float));

    if(layer17_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer17_depthwise_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (960 -> 320 축소)
    pointwise_conv_1x1(layer17_depthwise_buf, features_17_conv_2_weight, layer17_out_buf, LAYER17_EXP_C, LAYER17_OUT_C, LAYER17_OUT_H, LAYER17_OUT_W);

    //이전의 결과는 필요없으므로 해제
    free(layer17_depthwise_buf);

    //batch normalization 함수 호출
    batch_normalization(layer17_out_buf, LAYER17_OUT_C, LAYER17_OUT_H, LAYER17_OUT_W, features_17_conv_3_running_mean, features_17_conv_3_running_var, features_17_conv_3_weight, features_17_conv_3_bias);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Layer18 시작

    float *layer18_out_buf=(float*)calloc(LAYER18_OUT_SIZE, sizeof(float));//Layer18 출력 크기만큼 동적할당(0으로 초기화)

    if(layer18_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer17_out_buf);
        return 1;
    }

    //pointwise convolution 함수 호출 (320 -> 1280 확장)
    pointwise_conv_1x1(layer17_out_buf, features_18_0_weight, layer18_out_buf, LAYER18_IN_C, LAYER18_OUT_C, LAYER18_IN_H, LAYER18_IN_W);

    //Layer17 출력은 Layer18 pointwise convolution 이후 필요없으므로 해제
    free(layer17_out_buf);

    //batch normalization 함수 호출
    batch_normalization(layer18_out_buf, LAYER18_OUT_C, LAYER18_OUT_H, LAYER18_OUT_W, features_18_1_running_mean, features_18_1_running_var, features_18_1_weight, features_18_1_bias);

    //relu6 함수 호출
    relu6(layer18_out_buf, LAYER18_OUT_SIZE);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //AvgPool 시작

    float *avgpool_out_buf=(float*)calloc(AVGPOOL_OUT_SIZE, sizeof(float));//avgpool 출력 크기만큼 동적할당(0으로 초기화)

    if(avgpool_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(layer18_out_buf);
        return 1;
    }

    //average pooling 함수 호출
    avgpool_7x7(layer18_out_buf, avgpool_out_buf, AVGPOOL_IN_C, AVGPOOL_IN_H, AVGPOOL_IN_W);

    //Layer18 출력은 avgpool 이후 필요없으므로 해제
    free(layer18_out_buf);


    //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
    //Classifier 시작

    float *classifier_out_buf=(float*)calloc(CLASSIFIER_OUT_SIZE, sizeof(float));//classifier 출력 크기만큼 동적할당(0으로 초기화)

    if(classifier_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(avgpool_out_buf);
        return 1;
    }

    //classifier pointwise convolution 함수 호출 (1280 -> 1000)
    pointwise_conv_1x1(avgpool_out_buf, classifier_1_weight, classifier_out_buf, CLASSIFIER_IN_C, CLASSIFIER_OUT_C, CLASSIFIER_IN_H, CLASSIFIER_IN_W);

    //Avgpool 출력은 classifier 이후 필요없으므로 해제
    free(avgpool_out_buf);

    //classifier bias 더하기
    add_bias(classifier_out_buf, classifier_1_bias, CLASSIFIER_OUT_SIZE);


    //Softmax 시작

    float *softmax_out_buf=(float*)calloc(CLASSIFIER_OUT_SIZE, sizeof(float));//softmax 출력 크기만큼 동적할당(0으로 초기화)

    if(softmax_out_buf == NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation failed\n");
        free(classifier_out_buf);
        return 1;
    }

    //softmax 함수 호출
    softmax(classifier_out_buf, softmax_out_buf, CLASSIFIER_OUT_SIZE);

    //softmax 결과 중 상위 5개 class 출력
    print_top5_result(softmax_out_buf, CLASSIFIER_OUT_SIZE);

    //classifier 출력은 softmax 이후 필요없으므로 해제
    free(classifier_out_buf);


    //출력 스트림 생성(포인터와 연결)
    FILE *fpOut = fopen("softmax_finished.bin", "wb");

    if(fpOut == NULL)//출력 파일 생성 실패 예외처리
    {
        printf("Not available to write file\n");
        free(softmax_out_buf);
        return 1;
    }

    size_t write_count = fwrite(softmax_out_buf, sizeof(float), CLASSIFIER_OUT_SIZE, fpOut);//출력 버퍼에 있는 내용을 파일로 쓰기

    if(write_count != CLASSIFIER_OUT_SIZE)//제대로 안써진 경우 예외처리
    {
        printf("File write error\n");
        fclose(fpOut);
        free(softmax_out_buf);
        return 1;
    }

    fclose(fpOut);//출력 스트림 소멸

    //최종 출력 버퍼 해제
    free(softmax_out_buf);

    return 0;
}





void conv2d_3x3(const float *input, const float *weight, float *output, int in_ch, int out_ch, int in_height, int in_width, 
                int out_height, int out_width, int stride, int padding)
{
    int out_ch_idx, in_ch_idx, row, col, ker_row, ker_col, in_i, in_j;

    for(out_ch_idx=0; out_ch_idx<out_ch; out_ch_idx++)
    {
        for(row=0; row<out_height; row++)
        {
            for(col=0; col<out_width; col++)
            {
                for(in_ch_idx=0; in_ch_idx<in_ch; in_ch_idx++)
                {
                    for(ker_row=0; ker_row<KERNEL_SIZE; ker_row++)
                    {
                        for(ker_col=0; ker_col<KERNEL_SIZE; ker_col++)
                        {
                            in_i=row*stride+ker_row-padding;
                            in_j=col*stride+ker_col-padding;

                            if(in_i>=0 && in_i<in_height && in_j>=0 && in_j<in_width)
                            {
                                output[out_ch_idx * out_height * out_width + row * out_width + col] +=
                                input[in_ch_idx * in_height * in_width + in_i * in_width + in_j] *
                                weight[out_ch_idx * in_ch * KERNEL_SIZE * KERNEL_SIZE + in_ch_idx * KERNEL_SIZE * KERNEL_SIZE + ker_row * KERNEL_SIZE + ker_col];
                            }
                        }
                    }
                }
            }
        }
    }
    return;
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


void batch_normalization(float *data, int ch_num, int height, int width, const float *mean, const float *var, const float *gamma, const float *beta)
{
    int ch_idx, row, col;
    int idx;

    for(ch_idx=0; ch_idx<ch_num; ch_idx++)
    {
        for(row=0; row<height; row++)
        {
            for(col=0; col<width; col++)
            {
                idx = ch_idx * height * width + row * width + col;
                data[idx] = gamma[ch_idx] * (data[idx] - mean[ch_idx]) / sqrtf(var[ch_idx] + EPSILON) + beta[ch_idx];
            }
        }
    }
}


void relu6(float *data, int size)
{
    int i;

    for(i=0; i<size; i++)
    {
        if(data[i]<0.0f)
            data[i]=0.0f;

        else if(data[i]>6.0f)
            data[i]=6.0f;
    }
    return;
}


void depthwise_conv(const float *input, const float *weight, float *output, int ch_num, int in_height, int in_width, 
                    int out_height, int out_width, int stride, int padding)
{
    int ch_idx, row, col, ker_row, ker_col, in_i, in_j;

    for(ch_idx=0; ch_idx<ch_num; ch_idx++)
    {
        for(row=0; row<out_height; row++)
        {
            for(col=0; col<out_width; col++)
            {
                for(ker_row=0; ker_row<KERNEL_SIZE; ker_row++)
                {
                    for(ker_col=0; ker_col<KERNEL_SIZE; ker_col++)
                    {
                        in_i=row*stride+ker_row-padding;
                        in_j=col*stride+ker_col-padding;

                        if(in_i>=0 && in_i<in_height && in_j>=0 && in_j<in_width)
                        {
                            output[ch_idx * out_height * out_width + row * out_width + col] +=
                            input[ch_idx * in_height * in_width + in_i * in_width + in_j]
                            * weight[ch_idx * KERNEL_SIZE * KERNEL_SIZE + ker_row * KERNEL_SIZE + ker_col];
                        }
                    }
                }
            }
        }
    }
}


void skip_connection(const float *input, float *output, int size)
{
    int i;

    for(i=0; i<size; i++)
    {
        output[i]+=input[i];
    }

    return;
}


void avgpool_7x7(const float *input, float *output, int ch_num, int height, int width)
{
    int ch_idx, row, col;
    int idx;
    float sum;

    for(ch_idx=0; ch_idx<ch_num; ch_idx++)
    {
        sum = 0.0f;

        for(row=0; row<height; row++)
        {
            for(col=0; col<width; col++)
            {
                idx = ch_idx * height * width + row * width + col;
                sum += input[idx];
            }
        }

        output[ch_idx] = sum / (height * width);
    }

    return;
}


void add_bias(float *data, const float *bias, int size)
{
    int i;

    for(i=0; i<size; i++)
    {
        data[i] += bias[i];
    }

    return;
}


void softmax(const float *input, float *output, int size)
{
    int i;
    float max_value;
    float sum;

    max_value = input[0];

    for(i=1; i<size; i++)
    {
        if(input[i] > max_value)
            max_value = input[i];
    }

    sum = 0.0f;

    for(i=0; i<size; i++)
    {
        output[i] = expf(input[i] - max_value);
        sum += output[i];
    }

    for(i=0; i<size; i++)
    {
        output[i] = output[i] / sum;
    }

    return;
}

void print_top5_result(const float *data, int size)
{
    int i, j, k;
    int top_idx[5];
    float top_value[5];

    for(i=0; i<5; i++)
    {
        top_idx[i] = -1;
        top_value[i] = -1.0f;
    }

    for(i=0; i<size; i++)
    {
        for(j=0; j<5; j++)
        {
            if(data[i] > top_value[j])
            {
                for(k=4; k>j; k--)
                {
                    top_value[k] = top_value[k-1];
                    top_idx[k] = top_idx[k-1];
                }

                top_value[j] = data[i];
                top_idx[j] = i;
                break;
            }
        }
    }

    printf("========== Top-5 Result ==========%c", '\n');

    for(i=0; i<5; i++)
    {
        printf("Top-%d : class = %d, name = %s, probability = %.8f%c", i+1, top_idx[i], (char*)imagenet_class[top_idx[i]], top_value[i], '\n');
    }

    printf("==================================%c", '\n');

    return;
}
