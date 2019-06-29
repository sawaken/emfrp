#include "NestedMatch.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* tag, int* value) {
  static int counter = 0;
  *tag = counter;
  counter = (counter + 1) % 5;
  if (scanf("%d", value) == EOF) {
    exit(0);
  }
}

void Output(int* x) {
  printf("%d\n", *x);
}

int main() {
  ActivateNestedMatch();
}
