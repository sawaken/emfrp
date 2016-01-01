#include "LCDClock.h"
#include <stdio.h>
#include <stdlib.h>

void display(int n, int mask, char c) {
  if (!mask) {
    printf("--%c", c);
  } else {
    printf("%02d%c", n, c);
  }
}

void Input(int* btnMode, int* btnNext, int* btnRotate, int* pulse100ms) {
  if (scanf("%d %d %d %d", btnMode, btnNext, btnRotate, pulse100ms) == EOF) {
    exit(0);
  }
}
void Output(int* hour, int* min, int* sec, int* maskHour, int* maskMin, int* maskSec) {
  display(*hour, *maskHour, ':');
  display(*min, *maskMin, ':');
  display(*sec, *maskSec, '\n');
}

int main() {
  ActivateLCDClock();
}
