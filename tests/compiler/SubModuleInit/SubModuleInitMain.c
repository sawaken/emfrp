#include "SubModuleInit.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* x, int* y) {
  if (scanf("%d %d", x, y) == EOF) {
    exit(0);
  }
}

void Output(int* delay2X, int* delay2Y) {
  printf("%d %d\n", *delay2X, *delay2Y);
}

int main() {
  ActivateSubModuleInit();
}
