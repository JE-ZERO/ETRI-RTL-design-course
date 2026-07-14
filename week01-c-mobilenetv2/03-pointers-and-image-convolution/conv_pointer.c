#include <stdio.h>
#include <stdlib.h>

#define KERNEL_ROW 3
#define KERNEL_COL 3

int main()
{
    int i, j, k, l, in_i, in_j, input_size, stride, padding, weight[3][3]={{1,0,-1},{1,0,-1},{1,0,-1}};
    
    printf("Enter input size : ");
    scanf("%d", &input_size);

    int *pI=(int*)malloc(sizeof(int)*input_size*input_size);


    if(pI==NULL)//동적할당 실패 예외처리
    {
        printf("Memory allocation FAILED");
        return 0;
    }

    printf("Enter stride size : ");
    scanf("%d", &stride);
    printf("Enter padding size : ");
    scanf("%d", &padding);

    int NUMERATOR=input_size-KERNEL_ROW+2*padding;

    if(stride==0||NUMERATOR%stride!=0)//불가능한 stride 예외처리
    {
        printf("Stride is not available");
        free(pI);
        return 0;
    }

    int output_size=NUMERATOR/stride+1;


    //INPUT MATRIX 입력

    
    for(i=0; i<input_size; i++)//input matrix size(행)
    {
        printf("(ROW%d) Enter %d integers : ", i, input_size);
        for(j=0; j<input_size; j++)//input matrix size(열)
        {
            scanf("%d", (pI+input_size*i+j));
        }
    }

    /*
    //디버깅용 10*10 입력행렬(1~100)
    for(i=0; i<10; i++)//input matrix size(행)
    {
        for(j=0; j<10; j++)//input matrix size(열)
        {
            *(pI+10*i+j)=10*i+(j+1);
        }
    }
    */


    int *pO=(int*)calloc(output_size*output_size,sizeof(int));



    for(i=0; i<output_size; i++)//output 행 개수
    {
        for(j=0; j<output_size; j++)//output 열 개수
        {
            for(k=0; k<KERNEL_ROW; k++)//weight의 행 개수
            {
                for(l=0; l<KERNEL_COL; l++)//weight의 열 개수
                {
                    in_i=i*stride+k-padding;
                    in_j=j*stride+l-padding;

                    if(in_i>=0 && in_i<input_size && in_j>=0 && in_j<input_size)//기존 INPUT MATRIX의 index를 벗어나면 누산X
                        *(pO+output_size*i+j)+=*(pI+input_size*in_i+in_j)*weight[k][l];//출력 배열 하나씩에 대해 누산
                }
            }

        }
    }

    //output[i][j]==*(pO+output_size*i+j)
    //input[in_i][in_j]==*(pI+input_size*_i+in_j)

    
    printf("Output size : %d x %d\n", output_size, output_size);

    for(i=0; i<output_size; i++)//output  matrix 출력
    {
        for(j=0; j<output_size; j++)
        {
            printf("%d ", *(pO+output_size*i+j));//---------------------고쳐
        }
        
        printf("\n");
    }
    


    /*
    //디버깅용 행렬출력
    for(i=0; i<input_size; i++)//output  matrix 출력
    {
        for(j=0; j<input_size; j++)
        {
            printf("%d ", *(pI+10*i+j));//---------------------고쳐
        }
        
        printf("\n");
    }*/
    

    free(pI);
    free(pO);
    return 0;
}