#include <stdio.h>

int main()
{
    int n, i, j;

    while(1)
    {
        printf("Enter an integer : ");
        scanf("%d", &n);

        if(n==0)
            break;

        else
        {
            for(i=n; i>0; i--)
            {
            for(j=0; j<i; j++)
                {
                    printf("*");
                }

            printf("\n");
            }
        }
    }
    return 0;
}