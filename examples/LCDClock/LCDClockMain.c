#include "LCDClock.h"
#include "mbed.h"
#include "C12832_lcd.h"

C12832_LCD lcd;
Ticker t;
DigitalIn right(p16), left(p13), up(p15), down(p12);
int pulse100_flag = 0;

void timer_callback() {
  pulse100_flag = 1;
}

void display(int n, int mask, char c) {
  if (!mask) {
    lcd.printf("--%c", c);
  } else {
    lcd.printf("%02d%c", n, c);
  }
}

void Input(int* btnMode, int* btnNext, int* btnRotate, int* pulse100ms) {
  *btnMode = right.read();
  *btnNext = left.read();
  *btnRotate = up.read();
  *pulse100ms = pulse100_flag;
  pulse100_flag = 0;
}

void Output(int* hour, int* min, int* sec, int* maskHour, int* maskMin, int* maskSec) {
  lcd.cls();
  lcd.locate(45, 10);
  display(*hour, *maskHour, ':');
  display(*min, *maskMin, ':');
  display(*sec, *maskSec, '\n');
  wait(0.01);
}

int main() {
  t.attach(&timer_callback, 0.1);
  ActivateLCDClock();
}
