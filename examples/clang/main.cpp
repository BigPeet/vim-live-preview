#define FOO 0
#define CAT(x, y) x ## y
#define TStruct(T) struct CAT(S, T) { T x; }

int Foo();

struct S {
  int x;
};

TStruct(int);

int main() {
    S s{FOO};
    char c = '0';
    double d{0.0};
    char const *str = "Hello";
    return s.x + c + d + Foo() + str[0];
}
