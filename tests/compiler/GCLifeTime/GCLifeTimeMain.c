#include "GCLifeTime.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* a) {
  if (scanf("%d", a) == EOF) {
    exit(0);
  }
}

void Output(int* x) {
  printf("%d\n", *x);
}

int main() {
  ActivateGCLifeTime();
}
