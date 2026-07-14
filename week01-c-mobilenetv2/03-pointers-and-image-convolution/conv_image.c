#include <stdio.h>
#include <stdlib.h>

#define KERNEL_ROW 3
#define KERNEL_COL 3

#define INPUT_FILE "lenna8bit.raw"
#define OUTPUT_FILE "result.raw"

int check_stride(int input_size, int stride, int padding);
int get_output_size(int input_size, int stride, int padding);
int read_raw_image(unsigned char *pI, int input_size);
void conv2d_cnn(unsigned char *pI, unsigned char *pO, int input_size, int output_size, int stride, int padding, int threshold, int weight[KERNEL_ROW][KERNEL_COL]);
int save_raw_image(unsigned char *pO, int output_size);

int main()
{
    int input_size, stride, padding, threshold, output_size;
    int weight[3][3]={{1,0,-1},{1,0,-1},{1,0,-1}};
    
    printf("Enter input size : ");
    scanf("%d", &input_size);

    unsigned char *pI=(unsigned char*)malloc(sizeof(unsigned char)*input_size*input_size);

    if(pI==NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation FAILED");
        return 0;
    }

    printf("Enter stride size : ");
    scanf("%d", &stride);
    printf("Enter padding size : ");
    scanf("%d", &padding);
    printf("Enter threshold : ");
    scanf("%d", &threshold);

    if(check_stride(input_size, stride, padding)==0)//불가능한 stride 예외처리
    {
        printf("Stride is not available");
        free(pI);
        return 0;
    }

    if(threshold<0)//불가능한 threshold 예외처리
    {
        printf("Threshold is not available");
        free(pI);
        return 0;
    }

    output_size=get_output_size(input_size, stride, padding);

    if(read_raw_image(pI, input_size)==0)//raw 파일 입력 예외처리
    {
        printf("Raw file read FAILED");
        free(pI);
        return 0;
    }

    unsigned char *pO=(unsigned char*)calloc(output_size*output_size,sizeof(unsigned char));

    if(pO==NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation FAILED");
        free(pI);
        return 0;
    }

    conv2d_cnn(pI, pO, input_size, output_size, stride, padding, threshold, weight);

    if(save_raw_image(pO, output_size)==0)//raw 파일 출력 예외처리
    {
        printf("Raw file save FAILED");
        free(pI);
        free(pO);
        return 0;
    }

    printf("Input file : %s\n", INPUT_FILE);
    printf("Output file : %s\n", OUTPUT_FILE);
    printf("Output size : %d x %d\n", output_size, output_size);

    free(pI);
    free(pO);
    return 0;
}

int check_stride(int input_size, int stride, int padding)
{
    int NUMERATOR=input_size-KERNEL_ROW+2*padding;

    if(stride<=0||NUMERATOR<0||NUMERATOR%stride!=0)//불가능한 stride 예외처리
        return 0;

    return 1;
}

int get_output_size(int input_size, int stride, int padding)
{
    int NUMERATOR=input_size-KERNEL_ROW+2*padding;

    return NUMERATOR/stride+1;
}

int read_raw_image(unsigned char *pI, int input_size)
{
    FILE *fp=fopen(INPUT_FILE, "rb");

    if(fp==NULL)
        return 0;

    fread(pI, sizeof(unsigned char), input_size*input_size, fp);

    fclose(fp);

    return 1;
}

void conv2d_cnn(unsigned char *pI, unsigned char *pO, int input_size, int output_size, int stride, int padding, int threshold, int weight[KERNEL_ROW][KERNEL_COL])
{
    int i, j, k, l, in_i, in_j, sum;

    for(i=0; i<output_size; i++)//output 행 개수
    {
        for(j=0; j<output_size; j++)//output 열 개수
        {
            sum=0;

            for(k=0; k<KERNEL_ROW; k++)//weight의 행 개수
            {
                for(l=0; l<KERNEL_COL; l++)//weight의 열 개수
                {
                    in_i=i*stride+k-padding;
                    in_j=j*stride+l-padding;

                    if(in_i>=0 && in_i<input_size && in_j>=0 && in_j<input_size)//기존 INPUT MATRIX의 index를 벗어나면 누산X
                        sum+=*(pI+input_size*in_i+in_j)*weight[k][l];//출력 배열 하나씩에 대해 누산
                }
            }

            if(sum<0)//절댓값 처리
                sum=-sum;

            if(sum>=threshold)//threshold 이상이면 edge로 판단
                *(pO+output_size*i+j)=255;
            else
                *(pO+output_size*i+j)=0;
        }
    }
}

int save_raw_image(unsigned char *pO, int output_size)
{
    FILE *fp;

    fp=fopen(OUTPUT_FILE, "wb");

    if(fp==NULL)
        return 0;

    fwrite(pO, sizeof(unsigned char), output_size*output_size, fp);

    fclose(fp);

    return 1;
}