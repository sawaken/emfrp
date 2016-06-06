#include "LCDPositioner.h"
#include <stdio.h>
#include <stdlib.h>

void Input(int* up, int* down, int* left, int* right, int* pulse10ms) {
  if (scanf("%d %d %d %d %d", up, down, left, right, pulse10ms) == EOF) {
    exit(0);
  }
}
void Output(int* x, int* y) {
  printf("%d %d\n", *x, *y);
}
int main() {
  ActivateLCDPositioner();
}
