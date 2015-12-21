#include "UseData.h"
#include <stdio.h>
#include <stdlib.h>

int i = 0;

void Input() {
}

void Output(int* x) {
  printf("%d\n", *x);
  if (++i == 10) {
    exit(0);
  }
}

int main() {
  ActivateUseData();
}
