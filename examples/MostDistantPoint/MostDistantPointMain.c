#include "MostDistantPoint.h"
#include <stdio.h>

void Input(int* inX, int* inY) {
  scanf("%d %d", inX, inY);
}

void Output(int* outX, int* outY) {
  printf("%d %d\n", *outX, *outY);
}

int main() {
  ActivateMostDistantPoint();
}
