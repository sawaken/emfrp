#include "MostDistantPoint.h"
/* Primitive functions (Macros) */
#define _lt_(a, b) (a < b)
#define _plus_(a, b) (a + b)
#define _asterisk_(a, b) (a * b)
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
/* Global variables */
int node_memory_inX[2];
int node_memory_inY[2];
struct Tuple2_Int_Int* node_memory_point[2];
int node_memory_outX[2];
int node_memory_outY[2];
struct Tuple2_Int_Int memory_Tuple2_Int_Int[5];
int size_Tuple2_Int_Int = 5;
int counter_Tuple2_Int_Int = 0;
int Counter = 1;
int NodeSize = 3;
/* Static prototypes */
static struct Tuple2_Int_Int* Tuple2_0(int, int);
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int*, int);
static int node_point(int, int, struct Tuple2_Int_Int*, struct Tuple2_Int_Int**);
static struct Tuple2_Int_Int* init_point();
static int node_outX(struct Tuple2_Int_Int*, int*);
static int init_outX();
static int node_outY(struct Tuple2_Int_Int*, int*);
static int init_outY();
static int distant2_0(struct Tuple2_Int_Int*, struct Tuple2_Int_Int*);
static int snd_0(struct Tuple2_Int_Int*);
static int fst_0(struct Tuple2_Int_Int*);
static void refreshMark();
extern void Input(int*, int*);
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
static int node_point(int inX, int inY, struct Tuple2_Int_Int* point_at_last, struct Tuple2_Int_Int** output) {
  int _tmp001;
  struct Tuple2_Int_Int* _tmp000;
  _tmp001 = distant2_0(Tuple2_0(0, 0), point_at_last);
  if (1) {
    int _tmp003;
    int pvar0_d1 = _tmp001;
    struct Tuple2_Int_Int* _tmp002;
    _tmp003 = distant2_0(Tuple2_0(0, 0), Tuple2_0(inX, inY));
    if (1) {
      int _tmp005;
      int pvar1_d2 = _tmp003;
      struct Tuple2_Int_Int* _tmp004;
      _tmp005 = _lt_(pvar0_d1, pvar1_d2);
      if (_tmp005 == 1) {
        _tmp004 = Tuple2_0(inX, inY);
      }
      else if (_tmp005 == 0) {
        _tmp004 = point_at_last;
      }
      _tmp002 = _tmp004;
    }
    _tmp000 = _tmp002;
  }
  *output = _tmp000;
  return 1;
}
static struct Tuple2_Int_Int* init_point() {
  return Tuple2_0(0, 0);
}
static int node_outX(struct Tuple2_Int_Int* point, int* output) {
  int _tmp006;
  if (1) {
    struct Tuple2_Int_Int* pvar2_point = point;
    int pvar2_outX = point->value.Tuple2.member0;
    int pvar2_outY = point->value.Tuple2.member1;
    _tmp006 = pvar2_outX;
  }
  *output = _tmp006;
  return 1;
}
static int init_outX() {
  struct Tuple2_Int_Int* _tmp008;
  int _tmp007;
  _tmp008 = Tuple2_0(0, 0);
  if (1) {
    struct Tuple2_Int_Int* pvar3_point = _tmp008;
    int pvar3_outX = _tmp008->value.Tuple2.member0;
    int pvar3_outY = _tmp008->value.Tuple2.member1;
    _tmp007 = pvar3_outX;
  }
  return _tmp007;
}
static int node_outY(struct Tuple2_Int_Int* point, int* output) {
  int _tmp009;
  if (1) {
    struct Tuple2_Int_Int* pvar4_point = point;
    int pvar4_outX = point->value.Tuple2.member0;
    int pvar4_outY = point->value.Tuple2.member1;
    _tmp009 = pvar4_outY;
  }
  *output = _tmp009;
  return 1;
}
static int init_outY() {
  struct Tuple2_Int_Int* _tmp011;
  int _tmp010;
  _tmp011 = Tuple2_0(0, 0);
  if (1) {
    struct Tuple2_Int_Int* pvar5_point = _tmp011;
    int pvar5_outX = _tmp011->value.Tuple2.member0;
    int pvar5_outY = _tmp011->value.Tuple2.member1;
    _tmp010 = pvar5_outY;
  }
  return _tmp010;
}
static int distant2_0(struct Tuple2_Int_Int* pointA, struct Tuple2_Int_Int* pointB) {
  int _tmp013;
  int _tmp012;
  _tmp013 = _minus_(fst_0(pointA), fst_0(pointB));
  if (1) {
    int _tmp015;
    int pvar6_dx = _tmp013;
    int _tmp014;
    _tmp015 = _minus_(snd_0(pointA), snd_0(pointB));
    if (1) {
      int pvar7_dy = _tmp015;
      _tmp014 = _plus_(_asterisk_(pvar6_dx, pvar6_dx), _asterisk_(pvar7_dy, pvar7_dy));
    }
    _tmp012 = _tmp014;
  }
  return _tmp012;
}
static int snd_0(struct Tuple2_Int_Int* t) {
  int _tmp016;
  if (1) {
    int pvar8_x = t->value.Tuple2.member0;
    int pvar8_y = t->value.Tuple2.member1;
    _tmp016 = pvar8_y;
  }
  return _tmp016;
}
static int fst_0(struct Tuple2_Int_Int* t) {
  int _tmp017;
  if (1) {
    int pvar9_x = t->value.Tuple2.member0;
    int pvar9_y = t->value.Tuple2.member1;
    _tmp017 = pvar9_x;
  }
  return _tmp017;
}
static void refreshMark() {
  int i;
  for (i = 0; i < size_Tuple2_Int_Int; i++) {
    if (memory_Tuple2_Int_Int[i].mark < Counter) memory_Tuple2_Int_Int[i].mark = 0;
    else memory_Tuple2_Int_Int[i].mark -= Counter - 1;
  }
}
void ActivateMostDistantPoint() {
  int current_side = 0, last_side = 1;
  node_memory_point[last_side] = init_point();
  mark_Tuple2_Int_Int(node_memory_point[last_side], 1 + 3);
  node_memory_outX[last_side] = init_outX();
  node_memory_outY[last_side] = init_outY();
  Counter = NodeSize + 1;
  refreshMark();
  while (1) {
    Counter = 1;
    Input(&node_memory_inX[current_side], &node_memory_inY[current_side]);
    node_point(node_memory_inX[current_side], node_memory_inY[current_side], node_memory_point[last_side], &node_memory_point[current_side]);
    mark_Tuple2_Int_Int(node_memory_point[current_side], Counter + 3);
    Counter++;
    node_outX(node_memory_point[current_side], &node_memory_outX[current_side]);
    Counter++;
    node_outY(node_memory_point[current_side], &node_memory_outY[current_side]);
    Counter++;
    Output(&node_memory_outX[current_side], &node_memory_outY[current_side]);
    refreshMark();
    current_side ^= 1;
    last_side ^= 1;
  }
}
