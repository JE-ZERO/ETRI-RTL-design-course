#include <stdio.h>
#include <math.h>

double Activation_func(double x);
double Batch_norm(double mu, double var, double gamma, double beta, double epsilon);

int main()
{
    double num, result;

    printf("Enter a number : ");
    scanf("%f", &num);

    result=Activation_func(num);

    printf("%f", result);

    return 0;
}


double Activation_func(double x)
{
    if(x>0)
    {
        printf("number is bigger than 0");
        if(x>6){
            printf("number is bigger than 6");
            return 6;
        }

        else
        {
            printf("number is smaller than 0");
            return x;
        }
    }

    else
        return 0;
}