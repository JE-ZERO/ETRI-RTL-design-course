#include <stdio.h>

int Maxfinder(int a, int b, int c, int d);
int Avgfinder(int a, int b, int c, int d);

int main()
{
    int i, j, count=0, stride=2, arr[10][10]={0}, output[5][5]={0};

    for(i=0; i<10; i++)
    {
        for(j=0; j<10; j++)
        {
            arr[i][j]=count++;
        }
    }

    for(i=0; i<5; i++)
    {
        for(j=0; j<5; j++)
        {
            output[i][j]=Avgfinder(arr[i*stride][j*stride], arr[i*stride][j*stride+1], arr[i*stride+1][j*stride], arr[i*stride+1][j*stride+1]);
        }
    }

    for(i=0; i<5; i++)
    {
        for(j=0; j<5; j++)
        {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }
    return 0;
}


int Maxfinder(int a, int b, int c, int d)
{
    int max=a;

    if(b>max)
        max=b;

    if(c>max)
        max=c;

    if(d>max)
        max=d;

    return max;
}

int Avgfinder(int a, int b, int c, int d)
{
    int avg=(a+b+c+d)/4;

    return avg;
}