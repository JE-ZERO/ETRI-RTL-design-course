#include <stdio.h>
#define INPUT_ROW 10
#define INPUT_COL 10
#define KERNEL_ROW 3
#define KERNEL_COL 3

int main()
{
    int i, j, k, l, in_i, in_j, stride, padding, input[10][10]={0}, weight[3][3]={{1,0,-1},{1,0,-1},{1,0,-1}}, output[8][8]={0};

    
    //INPUT MATRIX 입력
    for(i=0; i<INPUT_ROW; i++)//input matrix의 행 개수
    {
        printf("Enter 10 integers : ");
        for(j=0; j<INPUT_COL; j++)//input matrix의 열 개수
        {
            scanf("%d", &input[i][j]);
        }
    }

    printf("Enter stride size : ");
    scanf("%d", &stride);
    printf("Enter padding size : ");
    scanf("%d", &padding);

    int NUMERATOR=INPUT_ROW-KERNEL_ROW+2*padding;

    if(NUMERATOR%stride!=0||stride==0)
    {
        printf("Stride is not available");
        return 0;
    }

    int OUTPUT_SIZE=(NUMERATOR)/stride+1;

    for(i=0; i<OUTPUT_SIZE; i++)//output 행 개수
    {
        for(j=0; j<OUTPUT_SIZE; j++)//output 열 개수
        {
            for(k=0; k<KERNEL_ROW; k++)//weight의 행 개수
            {
                for(l=0; l<KERNEL_COL; l++)//weight의 열 개수
                {
                    in_i=i*stride+k-padding;
                    in_j=j*stride+l-padding;

                    if(in_i>=0 && in_i<INPUT_ROW && in_j>=0 && in_j<INPUT_COL)//기존 INPUT MATRIX의 index를 벗어나면 누산X
                        output[i][j]+=input[in_i][in_j]*weight[k][l];//출력 배열 하나씩에 대해 누산
                }
            }

        }
    }

    printf("Output size : %d x %d\n", OUTPUT_SIZE, OUTPUT_SIZE);

    for(i=0; i<OUTPUT_SIZE; i++)//output  matrix 출력
    {
        for(j=0; j<OUTPUT_SIZE; j++)
        {
            printf("%d ", output[i][j]);
        }
        
        printf("\n");
    }

    return 0;
}