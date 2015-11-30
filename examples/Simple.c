#define _plus_(a, b) (a + b)
#define _asterisk_(a, b) (a * b)
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
static int node_node1(int, int, struct Tuple2_Int_Int**);
static int node_z(struct Tuple2_Int_Int*, int*);
//static void reloadMark(int, int, int);
static void reloadMark();
extern void Input(int*, int*);
extern void Output(int*);
void ActivateSimple();
struct Tuple2_Int_Int* value_node_node1[2];
int value_node_z[2];
int value_node_x[2];
int value_node_y[2];
struct Tuple2_Int_Int memory_Tuple2_Int_Int[1];
int count_Tuple2_Int_Int = 1;
int itr_Tuple2_Int_Int = 0;
int counter = 0;
//int counter_origin;
int N = 2;
static struct Tuple2_Int_Int* Tuple2_Tuple2_Int_Int(int member0, int member1) {
  struct Tuple2_Int_Int* x;
  while (1) {
    itr_Tuple2_Int_Int++;
    itr_Tuple2_Int_Int %= count_Tuple2_Int_Int;
    //if (counter_origin <= memory_Tuple2_Int_Int[itr_Tuple2_Int_Int].mark && memory_Tuple2_Int_Int[itr_Tuple2_Int_Int].mark <= counter) { x = memory_Tuple2_Int_Int + itr_Tuple2_Int_Int; break; }
    if (memory_Tuple2_Int_Int[itr_Tuple2_Int_Int].mark < counter) { x = memory_Tuple2_Int_Int + itr_Tuple2_Int_Int; break; }
  }
  x->value.Tuple2_Tuple2_Int_Int.member0 = member0;
  x->value.Tuple2_Tuple2_Int_Int.member1 = member1;
  return x;
}
static void mark_Tuple2_Int_Int(struct Tuple2_Int_Int* x, int mark) {
  x->mark = mark;
}
static int node_node1(int x, int y, struct Tuple2_Int_Int** output) {
  *output = Tuple2_Tuple2_Int_Int(_asterisk_(x, y), _plus_(x, y));
  return 1;
}
static int node_z(struct Tuple2_Int_Int* node1, int* output) {
  int _tmp000;
  if (1) {
    int a = node1->value.Tuple2_Tuple2_Int_Int.member0;
    int b = node1->value.Tuple2_Tuple2_Int_Int.member1;
    _tmp000 = _plus_(a, b);
  }
  *output = _tmp000;
  return 1;
}
static void reloadMark() {
  int i;
  for (i = 0; i < count_Tuple2_Int_Int; i++) {
    if (memory_Tuple2_Int_Int[i].mark < counter) memory_Tuple2_Int_Int[i].mark = 0;
    else memory_Tuple2_Int_Int[i].mark -= counter - 1;
    //if (s <= memory_Tuple2_Int_Int[i].mark && memory_Tuple2_Int_Int[i].mark <= t) memory_Tuple2_Int_Int[i].mark = mark;
  }
}
void ActivateSimple() {
  int current_side = 0, last_side = 1;
  while (1) {
    counter = 1;
    //counter_origin = counter;
    Input(&value_node_x[current_side], &value_node_y[current_side]);
    node_node1(value_node_x[current_side], value_node_y[current_side], &value_node_node1[current_side]);
    //mark_Tuple2_Int_Int(value_node1[current_side], (counter + 1) % (2 * N));
    mark_Tuple2_Int_Int(value_node_node1[current_side], counter + 1);
    counter++;
    node_z(value_node_node1[current_side], &value_node_z[current_side]);
    counter++;
    Output(&value_node_z[current_side]);
    //reloadMark(counter_origin, counter, (counter + 1) % (2 * N));
    reloadMark();
    current_side ^= 1;
    last_side ^= 1;
    //counter = (counter + 1) % (2 * N);

  }
}
