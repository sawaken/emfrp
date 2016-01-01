#include "LCDClock.h"
/* Primitive functions (Macros) */
#define _anpersand_anpersand(a, b) (a && b)
#define _eq__eq_(a, b) (a == b)
#define _exclamation__eq_(a, b) (a != b)
#define _parcent_(a, b) (a % b)
#define _plus_(a, b) (a + b)
#define _lt_(a, b) (a < b)
#define _slash_(a, b) (a / b)
#define _at__exclamation_(a) (!a)
/* Data types */
struct Time{
  int mark;
  union {
    struct {
      int member0;
      int member1;
      int member2;
    }Time;
  }value;
};
struct Tuple3_Int_Int_Int{
  int mark;
  union {
    struct {
      int member0;
      int member1;
      int member2;
    }Tuple3;
  }value;
};
struct Tuple3_Bool_Bool_Bool{
  int mark;
  union {
    struct {
      int member0;
      int member1;
      int member2;
    }Tuple3;
  }value;
};
/* Global variables */
int node_memory_btnMode[2];
int node_memory_btnNext[2];
int node_memory_btnRotate[2];
int node_memory_pulse100ms[2];
int node_memory_counter[2];
int node_memory_curMode[2];
int node_memory_curPos[2];
int node_memory_pulse1s[2];
int node_memory_flash[2];
struct Tuple3_Int_Int_Int* node_memory_anonymous70325029289080[2];
struct Tuple3_Bool_Bool_Bool* node_memory_anonymous70325030089620[2];
int node_memory_dh[2];
int node_memory_dm[2];
int node_memory_ds[2];
int node_memory_maskHour[2];
int node_memory_maskMin[2];
int node_memory_maskSec[2];
struct Time* node_memory_curTime[2];
struct Time* node_memory_anonymous70325029286600[2];
int node_memory_hour[2];
int node_memory_min[2];
int node_memory_sec[2];
struct Time memory_Time[3];
int size_Time = 3;
int counter_Time = 0;
struct Tuple3_Int_Int_Int memory_Tuple3_Int_Int_Int[1];
int size_Tuple3_Int_Int_Int = 1;
int counter_Tuple3_Int_Int_Int = 0;
struct Tuple3_Bool_Bool_Bool memory_Tuple3_Bool_Bool_Bool[1];
int size_Tuple3_Bool_Bool_Bool = 1;
int counter_Tuple3_Bool_Bool_Bool = 0;
int Counter = 1;
int NodeSize = 18;
/* Static prototypes */
static struct Time* Time_0(int, int, int);
static void mark_Time(struct Time*, int);
static struct Tuple3_Int_Int_Int* Tuple3_0(int, int, int);
static void mark_Tuple3_Int_Int_Int(struct Tuple3_Int_Int_Int*, int);
static struct Tuple3_Bool_Bool_Bool* Tuple3_1(int, int, int);
static void mark_Tuple3_Bool_Bool_Bool(struct Tuple3_Bool_Bool_Bool*, int);
static int init_btnMode();
static int init_btnNext();
static int init_btnRotate();
static int node_counter(int, int, int*);
static int init_counter();
static int node_curMode(int, int, int, int*);
static int init_curMode();
static int node_curPos(int, int, int, int*);
static int init_curPos();
static int node_pulse1s(int, int, int*);
static int node_flash(int, int*);
static int node_anonymous70325029289080(int, int, int, int, struct Tuple3_Int_Int_Int**);
static int node_anonymous70325030089620(int, int, int, struct Tuple3_Bool_Bool_Bool**);
static int node_dh(struct Tuple3_Int_Int_Int*, int*);
static int node_dm(struct Tuple3_Int_Int_Int*, int*);
static int node_ds(struct Tuple3_Int_Int_Int*, int*);
static int node_maskHour(struct Tuple3_Bool_Bool_Bool*, int*);
static int node_maskMin(struct Tuple3_Bool_Bool_Bool*, int*);
static int node_maskSec(struct Tuple3_Bool_Bool_Bool*, int*);
static int node_curTime(int, struct Time*, int, int, int, struct Time**);
static struct Time* init_curTime();
static int node_anonymous70325029286600(struct Time*, struct Time**);
static int node_hour(struct Time*, int*);
static int node_min(struct Time*, int*);
static int node_sec(struct Time*, int*);
static struct Time* roundingTime_0(struct Time*, int, int, int);
static struct Time* proceedTime_0(struct Time*);
static int editable_0(int);
static int positiveEdge_0(int, int);
static int nextMode_0(int);
static int nextPos_0(int);
static void refreshMark();
extern void Input(int*, int*, int*, int*);
extern void Output(int*, int*, int*, int*, int*, int*);
/* Functions, Constructors, GCMarkers, etc... */
static struct Time* Time_0(int member0, int member1, int member2) {
  struct Time* x;
  while (1) {
    counter_Time++;
    counter_Time %= size_Time;
    if (memory_Time[counter_Time].mark < Counter) { x = memory_Time + counter_Time; break; }
  }
  x->value.Time.member0 = member0;
  x->value.Time.member1 = member1;
  x->value.Time.member2 = member2;
  return x;
}
static void mark_Time(struct Time* x, int mark) {
  x->mark = mark;
}
static struct Tuple3_Int_Int_Int* Tuple3_0(int member0, int member1, int member2) {
  struct Tuple3_Int_Int_Int* x;
  while (1) {
    counter_Tuple3_Int_Int_Int++;
    counter_Tuple3_Int_Int_Int %= size_Tuple3_Int_Int_Int;
    if (memory_Tuple3_Int_Int_Int[counter_Tuple3_Int_Int_Int].mark < Counter) { x = memory_Tuple3_Int_Int_Int + counter_Tuple3_Int_Int_Int; break; }
  }
  x->value.Tuple3.member0 = member0;
  x->value.Tuple3.member1 = member1;
  x->value.Tuple3.member2 = member2;
  return x;
}
static void mark_Tuple3_Int_Int_Int(struct Tuple3_Int_Int_Int* x, int mark) {
  x->mark = mark;
}
static struct Tuple3_Bool_Bool_Bool* Tuple3_1(int member0, int member1, int member2) {
  struct Tuple3_Bool_Bool_Bool* x;
  while (1) {
    counter_Tuple3_Bool_Bool_Bool++;
    counter_Tuple3_Bool_Bool_Bool %= size_Tuple3_Bool_Bool_Bool;
    if (memory_Tuple3_Bool_Bool_Bool[counter_Tuple3_Bool_Bool_Bool].mark < Counter) { x = memory_Tuple3_Bool_Bool_Bool + counter_Tuple3_Bool_Bool_Bool; break; }
  }
  x->value.Tuple3.member0 = member0;
  x->value.Tuple3.member1 = member1;
  x->value.Tuple3.member2 = member2;
  return x;
}
static void mark_Tuple3_Bool_Bool_Bool(struct Tuple3_Bool_Bool_Bool* x, int mark) {
  x->mark = mark;
}
static int init_btnMode() {
  return 0;
}
static int init_btnNext() {
  return 0;
}
static int init_btnRotate() {
  return 0;
}
static int node_counter(int pulse100ms, int counter_at_last, int* output) {
  int _tmp000;
  if (pulse100ms == 1) {
    _tmp000 = _plus_(counter_at_last, 1);
  }
  else if (pulse100ms == 0) {
    _tmp000 = counter_at_last;
  }
  *output = _parcent_(_tmp000, 10);
  return 1;
}
static int init_counter() {
  return 0;
}
static int node_curMode(int btnMode_at_last, int btnMode, int curMode_at_last, int* output) {
  int _tmp002;
  int _tmp001;
  _tmp002 = positiveEdge_0(btnMode_at_last, btnMode);
  if (_tmp002 == 1) {
    _tmp001 = nextMode_0(curMode_at_last);
  }
  else if (_tmp002 == 0) {
    _tmp001 = curMode_at_last;
  }
  *output = _tmp001;
  return 1;
}
static int init_curMode() {
  return 0;
}
static int node_curPos(int btnNext_at_last, int btnNext, int curPos_at_last, int* output) {
  int _tmp004;
  int _tmp003;
  _tmp004 = positiveEdge_0(btnNext_at_last, btnNext);
  if (_tmp004 == 1) {
    _tmp003 = nextPos_0(curPos_at_last);
  }
  else if (_tmp004 == 0) {
    _tmp003 = curPos_at_last;
  }
  *output = _tmp003;
  return 1;
}
static int init_curPos() {
  return 0;
}
static int node_pulse1s(int counter, int counter_at_last, int* output) {
  *output = _anpersand_anpersand(_eq__eq_(counter, 0), _exclamation__eq_(counter_at_last, 0));
  return 1;
}
static int node_flash(int counter, int* output) {
  *output = _lt_(counter, 5);
  return 1;
}
static int node_anonymous70325029289080(int curMode, int btnRotate_at_last, int btnRotate, int curPos, struct Tuple3_Int_Int_Int** output) {
  int _tmp006;
  struct Tuple3_Int_Int_Int* _tmp005;
  _tmp006 = _anpersand_anpersand(editable_0(curMode), positiveEdge_0(btnRotate_at_last, btnRotate));
  if (_tmp006 == 1) {
    struct Tuple3_Int_Int_Int* _tmp007;
    if (curPos == 0) {
      _tmp007 = Tuple3_0(1, 0, 0);
    }
    else if (curPos == 1) {
      _tmp007 = Tuple3_0(0, 1, 0);
    }
    else if (curPos == 2) {
      _tmp007 = Tuple3_0(0, 0, 1);
    }
    _tmp005 = _tmp007;
  }
  else if (_tmp006 == 0) {
    _tmp005 = Tuple3_0(0, 0, 0);
  }
  *output = _tmp005;
  return 1;
}
static int node_anonymous70325030089620(int curMode, int flash, int curPos, struct Tuple3_Bool_Bool_Bool** output) {
  int _tmp009;
  struct Tuple3_Bool_Bool_Bool* _tmp008;
  _tmp009 = _anpersand_anpersand(editable_0(curMode), flash);
  if (_tmp009 == 1) {
    struct Tuple3_Bool_Bool_Bool* _tmp010;
    if (curPos == 0) {
      _tmp010 = Tuple3_1(0, 1, 1);
    }
    else if (curPos == 1) {
      _tmp010 = Tuple3_1(1, 0, 1);
    }
    else if (curPos == 2) {
      _tmp010 = Tuple3_1(1, 1, 0);
    }
    _tmp008 = _tmp010;
  }
  else if (_tmp009 == 0) {
    _tmp008 = Tuple3_1(1, 1, 1);
  }
  *output = _tmp008;
  return 1;
}
static int node_dh(struct Tuple3_Int_Int_Int* anonymous70325029289080, int* output) {
  int _tmp011;
  if (1) {
    int pvar0_dh = anonymous70325029289080->value.Tuple3.member0;
    int pvar0_dm = anonymous70325029289080->value.Tuple3.member1;
    int pvar0_ds = anonymous70325029289080->value.Tuple3.member2;
    _tmp011 = pvar0_dh;
  }
  *output = _tmp011;
  return 1;
}
static int node_dm(struct Tuple3_Int_Int_Int* anonymous70325029289080, int* output) {
  int _tmp012;
  if (1) {
    int pvar1_dh = anonymous70325029289080->value.Tuple3.member0;
    int pvar1_dm = anonymous70325029289080->value.Tuple3.member1;
    int pvar1_ds = anonymous70325029289080->value.Tuple3.member2;
    _tmp012 = pvar1_dm;
  }
  *output = _tmp012;
  return 1;
}
static int node_ds(struct Tuple3_Int_Int_Int* anonymous70325029289080, int* output) {
  int _tmp013;
  if (1) {
    int pvar2_dh = anonymous70325029289080->value.Tuple3.member0;
    int pvar2_dm = anonymous70325029289080->value.Tuple3.member1;
    int pvar2_ds = anonymous70325029289080->value.Tuple3.member2;
    _tmp013 = pvar2_ds;
  }
  *output = _tmp013;
  return 1;
}
static int node_maskHour(struct Tuple3_Bool_Bool_Bool* anonymous70325030089620, int* output) {
  int _tmp014;
  if (1) {
    int pvar3_maskHour = anonymous70325030089620->value.Tuple3.member0;
    int pvar3_maskMin = anonymous70325030089620->value.Tuple3.member1;
    int pvar3_maskSec = anonymous70325030089620->value.Tuple3.member2;
    _tmp014 = pvar3_maskHour;
  }
  *output = _tmp014;
  return 1;
}
static int node_maskMin(struct Tuple3_Bool_Bool_Bool* anonymous70325030089620, int* output) {
  int _tmp015;
  if (1) {
    int pvar4_maskHour = anonymous70325030089620->value.Tuple3.member0;
    int pvar4_maskMin = anonymous70325030089620->value.Tuple3.member1;
    int pvar4_maskSec = anonymous70325030089620->value.Tuple3.member2;
    _tmp015 = pvar4_maskMin;
  }
  *output = _tmp015;
  return 1;
}
static int node_maskSec(struct Tuple3_Bool_Bool_Bool* anonymous70325030089620, int* output) {
  int _tmp016;
  if (1) {
    int pvar5_maskHour = anonymous70325030089620->value.Tuple3.member0;
    int pvar5_maskMin = anonymous70325030089620->value.Tuple3.member1;
    int pvar5_maskSec = anonymous70325030089620->value.Tuple3.member2;
    _tmp016 = pvar5_maskSec;
  }
  *output = _tmp016;
  return 1;
}
static int node_curTime(int pulse1s, struct Time* curTime_at_last, int dh, int dm, int ds, struct Time** output) {
  struct Time* _tmp017;
  if (pulse1s == 1) {
    _tmp017 = roundingTime_0(proceedTime_0(curTime_at_last), dh, dm, ds);
  }
  else if (pulse1s == 0) {
    _tmp017 = roundingTime_0(curTime_at_last, dh, dm, ds);
  }
  *output = _tmp017;
  return 1;
}
static struct Time* init_curTime() {
  return Time_0(0, 0, 0);
}
static int node_anonymous70325029286600(struct Time* curTime, struct Time** output) {
  *output = curTime;
  return 1;
}
static int node_hour(struct Time* anonymous70325029286600, int* output) {
  int _tmp018;
  if (1) {
    int pvar6_hour = anonymous70325029286600->value.Time.member0;
    int pvar6_min = anonymous70325029286600->value.Time.member1;
    int pvar6_sec = anonymous70325029286600->value.Time.member2;
    _tmp018 = pvar6_hour;
  }
  *output = _tmp018;
  return 1;
}
static int node_min(struct Time* anonymous70325029286600, int* output) {
  int _tmp019;
  if (1) {
    int pvar7_hour = anonymous70325029286600->value.Time.member0;
    int pvar7_min = anonymous70325029286600->value.Time.member1;
    int pvar7_sec = anonymous70325029286600->value.Time.member2;
    _tmp019 = pvar7_min;
  }
  *output = _tmp019;
  return 1;
}
static int node_sec(struct Time* anonymous70325029286600, int* output) {
  int _tmp020;
  if (1) {
    int pvar8_hour = anonymous70325029286600->value.Time.member0;
    int pvar8_min = anonymous70325029286600->value.Time.member1;
    int pvar8_sec = anonymous70325029286600->value.Time.member2;
    _tmp020 = pvar8_sec;
  }
  *output = _tmp020;
  return 1;
}
static struct Time* roundingTime_0(struct Time* t, int dh, int dm, int ds) {
  struct Time* _tmp021;
  if (1) {
    int pvar9_h = t->value.Time.member0;
    int pvar9_m = t->value.Time.member1;
    int pvar9_s = t->value.Time.member2;
    _tmp021 = Time_0(_parcent_(_plus_(pvar9_h, dh), 24), _parcent_(_plus_(pvar9_m, dm), 60), _parcent_(_plus_(pvar9_s, ds), 60));
  }
  return _tmp021;
}
static struct Time* proceedTime_0(struct Time* t) {
  struct Time* _tmp022;
  if (1) {
    int _tmp024;
    int pvar10_h = t->value.Time.member0;
    int pvar10_m = t->value.Time.member1;
    int pvar10_s = t->value.Time.member2;
    struct Time* _tmp023;
    _tmp024 = _plus_(pvar10_s, 1);
    if (1) {
      int _tmp026;
      int pvar11_newS = _tmp024;
      struct Time* _tmp025;
      _tmp026 = _plus_(pvar10_m, _slash_(pvar11_newS, 60));
      if (1) {
        int _tmp028;
        int pvar12_newM = _tmp026;
        struct Time* _tmp027;
        _tmp028 = _plus_(pvar10_h, _slash_(pvar12_newM, 60));
        if (1) {
          int pvar13_newH = _tmp028;
          _tmp027 = Time_0(_parcent_(pvar13_newH, 24), _parcent_(pvar12_newM, 60), _parcent_(pvar11_newS, 60));
        }
        _tmp025 = _tmp027;
      }
      _tmp023 = _tmp025;
    }
    _tmp022 = _tmp023;
  }
  return _tmp022;
}
static int editable_0(int m) {
  int _tmp029;
  if (m == 0) {
    _tmp029 = 0;
  }
  else if (m == 1) {
    _tmp029 = 1;
  }
  return _tmp029;
}
static int positiveEdge_0(int a, int b) {
  return _anpersand_anpersand(_at__exclamation_(a), b);
}
static int nextMode_0(int m) {
  int _tmp030;
  if (m == 0) {
    _tmp030 = 1;
  }
  else if (m == 1) {
    _tmp030 = 0;
  }
  return _tmp030;
}
static int nextPos_0(int p) {
  int _tmp031;
  if (p == 0) {
    _tmp031 = 1;
  }
  else if (p == 1) {
    _tmp031 = 2;
  }
  else if (p == 2) {
    _tmp031 = 0;
  }
  return _tmp031;
}
static void refreshMark() {
  int i;
  for (i = 0; i < size_Time; i++) {
    if (memory_Time[i].mark < Counter) memory_Time[i].mark = 0;
    else memory_Time[i].mark -= Counter - 1;
  }
  for (i = 0; i < size_Tuple3_Int_Int_Int; i++) {
    if (memory_Tuple3_Int_Int_Int[i].mark < Counter) memory_Tuple3_Int_Int_Int[i].mark = 0;
    else memory_Tuple3_Int_Int_Int[i].mark -= Counter - 1;
  }
  for (i = 0; i < size_Tuple3_Bool_Bool_Bool; i++) {
    if (memory_Tuple3_Bool_Bool_Bool[i].mark < Counter) memory_Tuple3_Bool_Bool_Bool[i].mark = 0;
    else memory_Tuple3_Bool_Bool_Bool[i].mark -= Counter - 1;
  }
}
void ActivateLCDClock() {
  int current_side = 0, last_side = 1;
  node_memory_btnMode[last_side] = init_btnMode();
  node_memory_btnNext[last_side] = init_btnNext();
  node_memory_btnRotate[last_side] = init_btnRotate();
  node_memory_counter[last_side] = init_counter();
  node_memory_curMode[last_side] = init_curMode();
  node_memory_curPos[last_side] = init_curPos();
  node_memory_curTime[last_side] = init_curTime();
  mark_Time(node_memory_curTime[last_side], 14);
  Counter = NodeSize + 1;
  refreshMark();
  while (1) {
    Counter = 1;
    Input(&node_memory_btnMode[current_side], &node_memory_btnNext[current_side], &node_memory_btnRotate[current_side], &node_memory_pulse100ms[current_side]);
    node_counter(node_memory_pulse100ms[current_side], node_memory_counter[last_side], &node_memory_counter[current_side]);
    Counter++;
    node_curMode(node_memory_btnMode[last_side], node_memory_btnMode[current_side], node_memory_curMode[last_side], &node_memory_curMode[current_side]);
    Counter++;
    node_curPos(node_memory_btnNext[last_side], node_memory_btnNext[current_side], node_memory_curPos[last_side], &node_memory_curPos[current_side]);
    Counter++;
    node_pulse1s(node_memory_counter[current_side], node_memory_counter[last_side], &node_memory_pulse1s[current_side]);
    Counter++;
    node_flash(node_memory_counter[current_side], &node_memory_flash[current_side]);
    Counter++;
    node_anonymous70325029289080(node_memory_curMode[current_side], node_memory_btnRotate[last_side], node_memory_btnRotate[current_side], node_memory_curPos[current_side], &node_memory_anonymous70325029289080[current_side]);
    mark_Tuple3_Int_Int_Int(node_memory_anonymous70325029289080[current_side], Counter + 4);
    Counter++;
    node_anonymous70325030089620(node_memory_curMode[current_side], node_memory_flash[current_side], node_memory_curPos[current_side], &node_memory_anonymous70325030089620[current_side]);
    mark_Tuple3_Bool_Bool_Bool(node_memory_anonymous70325030089620[current_side], Counter + 6);
    Counter++;
    node_dh(node_memory_anonymous70325029289080[current_side], &node_memory_dh[current_side]);
    Counter++;
    node_dm(node_memory_anonymous70325029289080[current_side], &node_memory_dm[current_side]);
    Counter++;
    node_ds(node_memory_anonymous70325029289080[current_side], &node_memory_ds[current_side]);
    Counter++;
    node_maskHour(node_memory_anonymous70325030089620[current_side], &node_memory_maskHour[current_side]);
    Counter++;
    node_maskMin(node_memory_anonymous70325030089620[current_side], &node_memory_maskMin[current_side]);
    Counter++;
    node_maskSec(node_memory_anonymous70325030089620[current_side], &node_memory_maskSec[current_side]);
    Counter++;
    node_curTime(node_memory_pulse1s[current_side], node_memory_curTime[last_side], node_memory_dh[current_side], node_memory_dm[current_side], node_memory_ds[current_side], &node_memory_curTime[current_side]);
    mark_Time(node_memory_curTime[current_side], Counter + 18);
    Counter++;
    node_anonymous70325029286600(node_memory_curTime[current_side], &node_memory_anonymous70325029286600[current_side]);
    mark_Time(node_memory_anonymous70325029286600[current_side], Counter + 3);
    Counter++;
    node_hour(node_memory_anonymous70325029286600[current_side], &node_memory_hour[current_side]);
    Counter++;
    node_min(node_memory_anonymous70325029286600[current_side], &node_memory_min[current_side]);
    Counter++;
    node_sec(node_memory_anonymous70325029286600[current_side], &node_memory_sec[current_side]);
    Counter++;
    Output(&node_memory_hour[current_side], &node_memory_min[current_side], &node_memory_sec[current_side], &node_memory_maskHour[current_side], &node_memory_maskMin[current_side], &node_memory_maskSec[current_side]);
    refreshMark();
    current_side ^= 1;
    last_side ^= 1;
  }
}
