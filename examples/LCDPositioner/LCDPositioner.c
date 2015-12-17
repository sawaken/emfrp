#include "LCDPositioner.h"
/* Primitive functions (Macros) */
#define _plus_(a, b) (a + b)
#define _anpersand_anpersand(a, b) (a && b)
#define _eq__eq_(a, b) (a == b)
#define _parcent_(a, b) (a % b)
#define boolToInt(a) (a)
#define _minus_(a, b) (a - b)
/* Data types */
struct Tuple2_Int_Int{
  int mark;
  union {
    struct {
      int member0;
      int member1;
    }Tuple2;
  }value;
};
struct Tuple2_Bool_Int{
  int mark;
  union {
    struct {
      int member0;
      int member1;
    }Tuple2;
  }value;
};
/* Global variables */
int node_memory_up[2];
int node_memory_down[2];
int node_memory_left[2];
int node_memory_right[2];
int node_memory_pulse10ms[2];
struct Tuple2_Bool_Int* node_memory_k[2];
int node_memory_dx[2];
int node_memory_dy[2];
int node_memory_pulse40ms[2];
int node_memory_pulse40msCount[2];
struct Tuple2_Int_Int* node_memory_pos[2];
int node_memory_x[2];
int node_memory_y[2];
struct Tuple2_Bool_Int memory_Tuple2_Bool_Int[2];
int size_Tuple2_Bool_Int = 2;
int counter_Tuple2_Bool_Int = 0;
struct Tuple2_Int_Int memory_Tuple2_Int_Int[2];
int size_Tuple2_Int_Int = 2;
int counter_Tuple2_Int_Int = 0;
int Counter = 1;
int NodeSize = 8;
/* Static prototypes */
static struct Tuple2_Int_Int* Tuple2_0(int, int);
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int*, int);
static struct Tuple2_Bool_Int* Tuple2_1(int, int);
static void mark_Tuple2_Bool_Int(struct Tuple2_Bool_Int*, int);
static int node_k(int, int, struct Tuple2_Bool_Int**);
static struct Tuple2_Bool_Int* init_k();
static int node_dx(int, int, int*);
static int node_dy(int, int, int*);
static int node_pulse40ms(struct Tuple2_Bool_Int*, int*);
static int init_pulse40ms();
static int node_pulse40msCount(struct Tuple2_Bool_Int*, int*);
static int init_pulse40msCount();
static int node_pos(int, int, int, int, int, struct Tuple2_Int_Int*, struct Tuple2_Int_Int**);
static struct Tuple2_Int_Int* init_pos();
static int node_x(struct Tuple2_Int_Int*, int*);
static int init_x();
static int node_y(struct Tuple2_Int_Int*, int*);
static int init_y();
static void refreshMark();
extern void Input(int*, int*, int*, int*, int*);
extern void Output(int*, int*);
/* Functions, Constructors, GCMarkers, etc... */
static struct Tuple2_Int_Int* Tuple2_0(int member0, int member1) {
  struct Tuple2_Int_Int* x;
  while (1) {
    counter_Tuple2_Int_Int++;
    counter_Tuple2_Int_Int %= size_Tuple2_Int_Int;
    if (memory_Tuple2_Int_Int[counter_Tuple2_Int_Int].mark < Counter) { x = memory_Tuple2_Int_Int + counter_Tuple2_Int_Int; break; }
  }
  x->value.Tuple2.member0 = member0;
  x->value.Tuple2.member1 = member1;
  return x;
}
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int* x, int mark) {
  x->mark = mark;
}
static struct Tuple2_Bool_Int* Tuple2_1(int member0, int member1) {
  struct Tuple2_Bool_Int* x;
  while (1) {
    counter_Tuple2_Bool_Int++;
    counter_Tuple2_Bool_Int %= size_Tuple2_Bool_Int;
    if (memory_Tuple2_Bool_Int[counter_Tuple2_Bool_Int].mark < Counter) { x = memory_Tuple2_Bool_Int + counter_Tuple2_Bool_Int; break; }
  }
  x->value.Tuple2.member0 = member0;
  x->value.Tuple2.member1 = member1;
  return x;
}
static void mark_Tuple2_Bool_Int(struct Tuple2_Bool_Int* x, int mark) {
  x->mark = mark;
}
static int node_k(int pulse10ms, int pulse40msCount_at_last, struct Tuple2_Bool_Int** output) {
  int _tmp001;
  struct Tuple2_Bool_Int* _tmp000;
  _tmp001 = _parcent_(_plus_(pulse40msCount_at_last, boolToInt(pulse10ms)), 4);
  if (1) {
    int pvar0_c = _tmp001;
    _tmp000 = Tuple2_1(_anpersand_anpersand(_eq__eq_(pvar0_c, 0), pulse10ms), pvar0_c);
  }
  *output = _tmp000;
  return 1;
}
static struct Tuple2_Bool_Int* init_k() {
  return Tuple2_1(0, 0);
}
static int node_dx(int right, int left, int* output) {
  *output = _minus_(boolToInt(right), boolToInt(left));
  return 1;
}
static int node_dy(int down, int up, int* output) {
  *output = _minus_(boolToInt(down), boolToInt(up));
  return 1;
}
static int node_pulse40ms(struct Tuple2_Bool_Int* k, int* output) {
  int _tmp002;
  if (1) {
    struct Tuple2_Bool_Int* pvar1_k = k;
    int pvar1_pulse40ms = k->value.Tuple2.member0;
    int pvar1_pulse40msCount = k->value.Tuple2.member1;
    _tmp002 = pvar1_pulse40ms;
  }
  *output = _tmp002;
  return 1;
}
static int init_pulse40ms() {
  struct Tuple2_Bool_Int* _tmp004;
  int _tmp003;
  _tmp004 = Tuple2_1(0, 0);
  if (1) {
    struct Tuple2_Bool_Int* pvar2_k = _tmp004;
    int pvar2_pulse40ms = _tmp004->value.Tuple2.member0;
    int pvar2_pulse40msCount = _tmp004->value.Tuple2.member1;
    _tmp003 = pvar2_pulse40ms;
  }
  return _tmp003;
}
static int node_pulse40msCount(struct Tuple2_Bool_Int* k, int* output) {
  int _tmp005;
  if (1) {
    struct Tuple2_Bool_Int* pvar3_k = k;
    int pvar3_pulse40ms = k->value.Tuple2.member0;
    int pvar3_pulse40msCount = k->value.Tuple2.member1;
    _tmp005 = pvar3_pulse40msCount;
  }
  *output = _tmp005;
  return 1;
}
static int init_pulse40msCount() {
  struct Tuple2_Bool_Int* _tmp007;
  int _tmp006;
  _tmp007 = Tuple2_1(0, 0);
  if (1) {
    struct Tuple2_Bool_Int* pvar4_k = _tmp007;
    int pvar4_pulse40ms = _tmp007->value.Tuple2.member0;
    int pvar4_pulse40msCount = _tmp007->value.Tuple2.member1;
    _tmp006 = pvar4_pulse40msCount;
  }
  return _tmp006;
}
static int node_pos(int pulse40ms, int x_at_last, int dx, int y_at_last, int dy, struct Tuple2_Int_Int* pos_at_last, struct Tuple2_Int_Int** output) {
  struct Tuple2_Int_Int* _tmp008;
  if (pulse40ms == 1) {
    _tmp008 = Tuple2_0(_plus_(x_at_last, dx), _plus_(y_at_last, dy));
  }
  else if (pulse40ms == 0) {
    _tmp008 = pos_at_last;
  }
  *output = _tmp008;
  return 1;
}
static struct Tuple2_Int_Int* init_pos() {
  return Tuple2_0(0, 0);
}
static int node_x(struct Tuple2_Int_Int* pos, int* output) {
  int _tmp009;
  if (1) {
    struct Tuple2_Int_Int* pvar5_pos = pos;
    int pvar5_x = pos->value.Tuple2.member0;
    int pvar5_y = pos->value.Tuple2.member1;
    _tmp009 = pvar5_x;
  }
  *output = _tmp009;
  return 1;
}
static int init_x() {
  struct Tuple2_Int_Int* _tmp011;
  int _tmp010;
  _tmp011 = Tuple2_0(0, 0);
  if (1) {
    struct Tuple2_Int_Int* pvar6_pos = _tmp011;
    int pvar6_x = _tmp011->value.Tuple2.member0;
    int pvar6_y = _tmp011->value.Tuple2.member1;
    _tmp010 = pvar6_x;
  }
  return _tmp010;
}
static int node_y(struct Tuple2_Int_Int* pos, int* output) {
  int _tmp012;
  if (1) {
    struct Tuple2_Int_Int* pvar7_pos = pos;
    int pvar7_x = pos->value.Tuple2.member0;
    int pvar7_y = pos->value.Tuple2.member1;
    _tmp012 = pvar7_y;
  }
  *output = _tmp012;
  return 1;
}
static int init_y() {
  struct Tuple2_Int_Int* _tmp014;
  int _tmp013;
  _tmp014 = Tuple2_0(0, 0);
  if (1) {
    struct Tuple2_Int_Int* pvar8_pos = _tmp014;
    int pvar8_x = _tmp014->value.Tuple2.member0;
    int pvar8_y = _tmp014->value.Tuple2.member1;
    _tmp013 = pvar8_y;
  }
  return _tmp013;
}
static void refreshMark() {
  int i;
  for (i = 0; i < size_Tuple2_Bool_Int; i++) {
    if (memory_Tuple2_Bool_Int[i].mark < Counter) memory_Tuple2_Bool_Int[i].mark = 0;
    else memory_Tuple2_Bool_Int[i].mark -= Counter - 1;
  }
  for (i = 0; i < size_Tuple2_Int_Int; i++) {
    if (memory_Tuple2_Int_Int[i].mark < Counter) memory_Tuple2_Int_Int[i].mark = 0;
    else memory_Tuple2_Int_Int[i].mark -= Counter - 1;
  }
}
void ActivateLCDPositioner() {
  int current_side = 0, last_side = 1;
  node_memory_k[last_side] = init_k();
  mark_Tuple2_Bool_Int(node_memory_k[last_side], 0);
  node_memory_pulse40ms[last_side] = init_pulse40ms();
  node_memory_pulse40msCount[last_side] = init_pulse40msCount();
  node_memory_pos[last_side] = init_pos();
  mark_Tuple2_Int_Int(node_memory_pos[last_side], 6);
  node_memory_x[last_side] = init_x();
  node_memory_y[last_side] = init_y();
  Counter = NodeSize + 1;
  refreshMark();
  while (1) {
    Counter = 1;
    Input(&node_memory_up[current_side], &node_memory_down[current_side], &node_memory_left[current_side], &node_memory_right[current_side], &node_memory_pulse10ms[current_side]);
    node_k(node_memory_pulse10ms[current_side], node_memory_pulse40msCount[last_side], &node_memory_k[current_side]);
    mark_Tuple2_Bool_Int(node_memory_k[current_side], Counter + 4);
    Counter++;
    node_dx(node_memory_right[current_side], node_memory_left[current_side], &node_memory_dx[current_side]);
    Counter++;
    node_dy(node_memory_down[current_side], node_memory_up[current_side], &node_memory_dy[current_side]);
    Counter++;
    node_pulse40ms(node_memory_k[current_side], &node_memory_pulse40ms[current_side]);
    Counter++;
    node_pulse40msCount(node_memory_k[current_side], &node_memory_pulse40msCount[current_side]);
    Counter++;
    node_pos(node_memory_pulse40ms[current_side], node_memory_x[last_side], node_memory_dx[current_side], node_memory_y[last_side], node_memory_dy[current_side], node_memory_pos[last_side], &node_memory_pos[current_side]);
    mark_Tuple2_Int_Int(node_memory_pos[current_side], Counter + 8);
    Counter++;
    node_x(node_memory_pos[current_side], &node_memory_x[current_side]);
    Counter++;
    node_y(node_memory_pos[current_side], &node_memory_y[current_side]);
    Counter++;
    Output(&node_memory_x[current_side], &node_memory_y[current_side]);
    refreshMark();
    current_side ^= 1;
    last_side ^= 1;
  }
}
