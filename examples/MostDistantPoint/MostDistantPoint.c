#define _plus_(a, b) (a + b)
#define _asterisk_(a, b) (a * b)
#define _lt_(a, b) (a < b)
struct Tuple2_Int_Int{
  int mark;
  union {
    struct {
      int member0;
      int member1;
    }Tuple2_Tuple2_Int_Int;
  }value;
};
static struct Tuple2_Int_Int* Tuple2_Tuple2_Int_Int(int, int);
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int*, int);
static struct Tuple2_Int_Int* distant_Tuple2_Int_Int_Tuple2_Int_Int(struct Tuple2_Int_Int*, struct Tuple2_Int_Int*);
static int node_distantPoint(int, int, struct Tuple2_Int_Int*, struct Tuple2_Int_Int**);
static int node_outX(struct Tuple2_Int_Int*, int*);
static int node_outY(struct Tuple2_Int_Int*, int*);
static struct Tuple2_Int_Int* init_node_distantPoint();
static void reloadMark();
extern void Input(int*, int*);
extern void Output(int*, int*);
void ActivateMostDistantPoint();
struct Tuple2_Int_Int* value_node_distantPoint[2];
int value_node_outX[2];
int value_node_outY[2];
int value_node_inX[2];
int value_node_inY[2];
struct Tuple2_Int_Int memory_Tuple2_Int_Int[2];
int count_Tuple2_Int_Int = 2;
int itr_Tuple2_Int_Int = 0;
int counter = 1;
int N = 3;
static struct Tuple2_Int_Int* Tuple2_Tuple2_Int_Int(int member0, int member1) {
  struct Tuple2_Int_Int* x;
  while (1) {
    itr_Tuple2_Int_Int++;
    itr_Tuple2_Int_Int %= count_Tuple2_Int_Int;
    if (memory_Tuple2_Int_Int[itr_Tuple2_Int_Int].mark < counter) { x = memory_Tuple2_Int_Int + itr_Tuple2_Int_Int; break; }
  }
  x->value.Tuple2_Tuple2_Int_Int.member0 = member0;
  x->value.Tuple2_Tuple2_Int_Int.member1 = member1;
  return x;
}
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int* x, int mark) {
  x->mark = mark;
}
static struct Tuple2_Int_Int* distant_Tuple2_Int_Int_Tuple2_Int_Int(struct Tuple2_Int_Int* a, struct Tuple2_Int_Int* b) {
  struct Tuple2_Int_Int* _tmp000;
  if (1) {
    int ax = a->value.Tuple2_Tuple2_Int_Int.member0;
    int ay = a->value.Tuple2_Tuple2_Int_Int.member1;
    struct Tuple2_Int_Int* _tmp001;
    if (1) {
      int _tmp003;
      int bx = b->value.Tuple2_Tuple2_Int_Int.member0;
      int by = b->value.Tuple2_Tuple2_Int_Int.member1;
      struct Tuple2_Int_Int* _tmp002;
      _tmp003 = _plus_(_asterisk_(ax, ax), _asterisk_(ay, ay));
      if (1) {
        int _tmp005;
        int distantA = _tmp003;
        struct Tuple2_Int_Int* _tmp004;
        _tmp005 = _plus_(_asterisk_(bx, bx), _asterisk_(by, by));
        if (1) {
          int _tmp007;
          int distantB = _tmp005;
          struct Tuple2_Int_Int* _tmp006;
          _tmp007 = _lt_(distantA, distantB);
          if (_tmp007 == 1) {
            _tmp006 = b;
          }
          else if (_tmp007 == 0) {
            _tmp006 = a;
          }
          _tmp004 = _tmp006;
        }
        _tmp002 = _tmp004;
      }
      _tmp001 = _tmp002;
    }
    _tmp000 = _tmp001;
  }
  return _tmp000;
}
static int node_distantPoint(int inX, int inY, struct Tuple2_Int_Int* l, struct Tuple2_Int_Int** output) {
  *output = distant_Tuple2_Int_Int_Tuple2_Int_Int(Tuple2_Tuple2_Int_Int(inX, inY), l);
  return 1;
}
static int node_outX(struct Tuple2_Int_Int* p, int* output) {
  int _tmp000;
  if (1) {
    int x = p->value.Tuple2_Tuple2_Int_Int.member0;
    int y = p->value.Tuple2_Tuple2_Int_Int.member1;
    _tmp000 = x;
  }
  *output = _tmp000;
  return 1;
}
static int node_outY(struct Tuple2_Int_Int* p, int* output) {
  int _tmp000;
  if (1) {
    int x = p->value.Tuple2_Tuple2_Int_Int.member0;
    int y = p->value.Tuple2_Tuple2_Int_Int.member1;
    _tmp000 = y;
  }
  *output = _tmp000;
  return 1;
}
static struct Tuple2_Int_Int* init_node_distantPoint() {
  return Tuple2_Tuple2_Int_Int(0, 0);
}
static void reloadMark() {
  int i;
  for (i = 0; i < count_Tuple2_Int_Int; i++) {
    if (memory_Tuple2_Int_Int[i].mark < counter) memory_Tuple2_Int_Int[i].mark = 0;
    else memory_Tuple2_Int_Int[i].mark -= counter - 1;
  }
}
void ActivateMostDistantPoint() {
  value_node_distantPoint[1] = init_node_distantPoint();
  mark_Tuple2_Int_Int(value_node_distantPoint[1], 1 + 3);
  counter = 4;
  reloadMark();
  int current_side = 0, last_side = 1;
  while (1) {
    counter = 1;
    Input(&value_node_inX[current_side], &value_node_inY[current_side]);
    node_distantPoint(value_node_inX[current_side], value_node_inY[current_side], value_node_distantPoint[last_side], &value_node_distantPoint[current_side]);
    mark_Tuple2_Int_Int(value_node_distantPoint[current_side], counter + 3);
    counter++;
    node_outX(value_node_distantPoint[current_side], &value_node_outX[current_side]);
    counter++;
    node_outY(value_node_distantPoint[current_side], &value_node_outY[current_side]);
    counter++;
    Output(&value_node_outX[current_side], &value_node_outY[current_side]);
    reloadMark();
    current_side ^= 1;
    last_side ^= 1;
  }
}
