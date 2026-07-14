#include <stdio.h>

int main()
{
    int i=2,j=1, i_max=9, j_max=9;


    while(1)
    {
        if(j<j_max+1)
        {
            printf("%d * %d = %d\n", i, j, i*j);
            j++;
        }

        else if(j==j_max+1)
        {
            i++, j=1;
            if(i==i_max+1)
            {
                break;
            }
        }

        else
        {
            printf("ERROR");
            break;
        }

    }
    return 0;
}