#include "ComplexDataType.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* i) {
  if (scanf("%d", i) == EOF) {
    exit(0);
  }
}
void Output(int* out1, double* out2) {
  printf("%d %.3lf\n", *out1, *out2);
}
int main() {
  ActivateComplexDataType();
}
