#include "UseSubModule.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* x) {
  if (scanf("%d", x) == EOF) {
    exit(0);
  }
}
void Output(int* a1, int* b1, int* a2, int* b2) {
  printf("%d %d %d %d\n", *a1, *b1, *a2, *b2);
}
int main() {
  ActivateUseSubModule();
}
