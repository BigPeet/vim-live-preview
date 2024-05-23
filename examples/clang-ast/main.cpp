int Foo();

struct S {
  int x;
};

int main() {
    S s{0};
    char c = '0';
    double d{0.0};
    return s.x + c + d + Foo();
}
