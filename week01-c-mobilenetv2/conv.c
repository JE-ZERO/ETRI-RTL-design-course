#include <stdio.h>

int main()
{
    int i, j, input[5], weight[3]={1,0,-1}, output[3]={0,0,0};


    printf("Enter 5 integers : ");
    for(i=0; i<5; i++)
    {
        scanf("%d", &input[i]);
    }

    for(i=0; i<3; i++)//output 크기만큼 반복
    {
        for(j=0; j<3; j++)//weight 크기만큼 반복
        {
            output[i]+=input[i+j]*weight[j];//출력 배열 하나씩에 대해 accumulation
        }
    }

    for(i=0; i<3; i++)//출력
    {
        printf("%d ", output[i]);
    }

    return 0;
}