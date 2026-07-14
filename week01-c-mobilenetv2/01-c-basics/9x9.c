#include <stdio.h>

int main()
{
    int i=2,j=1, i_max=9, j_max=9;

    while((i<i_max+1))
    {
        if(j<j_max+1)
        {
            printf("%d * %d = %d\n", i, j, i*j);
            j++;
        }

        else
        {
            i++, j=1;
        }
    }
    return 0;
}