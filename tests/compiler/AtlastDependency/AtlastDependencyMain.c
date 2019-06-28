#include "AtlastDependency.h"
#include <stdio.h>
#include <stdlib.h>

int i = 0;

void Input() {
}

void Output(int* delay3A) {
  printf("%d\n", *delay3A);
  if (++i == 10) {
    exit(0);
  }
}

int main() {
  ActivateAtlastDependency();
}
