#include <stdio.h>

int main()
{
    int i, j, k, l, input[5][5]={0}, weight[3][3]={{0,0,0},{1,0,0},{0,0,0}}, output[3][3]={0};


    for(i=0; i<5; i++)
    {
        printf("Enter 5 integers : ");
        for(j=0; j<5; j++)
        {
            scanf("%d", &input[i][j]);
        }

    }

    for(i=0; i<3; i++)//output 크기만큼 반복
    {
        for(j=0; j<3; j++)//weight 크기만큼 반복
        {
            for(k=0; k<3; k++)
            {
                for(l=0; l<3; l++)
                output[i][j]+=input[k+i][l+j]*weight[k][l];//출력 배열 하나씩에 대해 accumulation
            }

        }
    }

    for(i=0; i<3; i++)//output  matrix 출력
    {
        for(j=0; j<3; j++)
        {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }

    return 0;
}