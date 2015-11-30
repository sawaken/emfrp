#include <stdio.h>

extern void ActivateSimple();

void Input(int* x, int* y)
{
  scanf("%d %d", x, y);
}

void Output(int* z)
{
  printf("%d\n", *z);
}

int main()
{
  ActivateSimple();
}
