# cpp: call arguments run right to left under x86-64 g++, so a read after a call sees the old value

be-cpp emits every Temper call, operator and string interpolation as a
single C++ call with its arguments in place. C++ does not fix the order
those arguments are evaluated in, and x86-64 g++ evaluates them right to
left. A field read that comes after a call changing that field reads the
old value:

```
x86-64 g++ 14   bump=1 n=0 | args 2 1 | plus 32
js              bump=1 n=1 | args 2 2 | plus 33
Apple clang 21  bump=1 n=1 | args 2 2 | plus 33
```

This is why the new functional test `classes/write-back-through-field`
in #531 fails on cpp in CI with `most=0` and `n=3`.

## Source

[`later-read/src/main.temper.md`](later-read/src/main.temper.md):

```temper
class Counter {
  public var n: Int = 0;
  public bump(): Int { n += 1; n }
}

let show(a: Int, b: Int): String { "${ a } ${ b }" }

let c = new Counter();
console.log("bump=${ c.bump() } n=${ c.n }");
console.log("args ${ show(c.bump(), c.n) }");
console.log("plus ${ c.bump() * 10 + c.n }");
```

```sh
./repro.sh 18-cpp-argument-order/later-read cpp
./repro.sh 18-cpp-argument-order/later-read js
./18-cpp-argument-order/run-gcc.sh
```

`repro.sh ... cpp` uses whatever `g++` is on the PATH. On macOS that is
clang, which evaluates left to right and prints the expected output.
`run-gcc.sh` builds the same library for cpp and compiles and runs the
generated C++ with g++ 14 in a `linux/amd64` Docker container.

## Output

On upstream `ffba652a`.

cpp, x86-64 g++ 14.4.0, exit code 0:

```
bump=1 n=0
args 2 1
plus 32
```

js, and cpp with Apple clang 21, exit code 0:

```
bump=1 n=1
args 2 2
plus 33
```

The same generated C++ under arm64 g++ 14.4.0 also prints the js output.

## What the cpp build writes

`temper.out/cpp/later-read/init.cpp`:

```cpp
temper::core::Console::log(console_0, temper::core::cat("bump=", temper::core::Int::toString(c->bump()), " n=", temper::core::Int::toString(c->get_n())));
temper::core::Console::log(console_0, temper::core::cat("args ", show(c->bump(), c->get_n())));
temper::core::Console::log(console_0, temper::core::cat("plus ", temper::core::Int::toString(temper::core::Int::add(temper::core::Int::mul(c->bump(), 10), c->get_n()))));
```

`c->get_n()` is evaluated before `c->bump()` in each of the three.

## Expected

Arguments are evaluated left to right, as on js and the other backends,
whatever C++ compiler builds the output.

## Notes

In upstream `ffba652a`:

- `be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppTranslator.kt:1014-1026`:
  a call to inline support code (`cat` for `StrCat`, `Int::add` for
  `PlusIntInt`, from `CppSupportNetwork.kt:119` and `:87`) translates each
  argument with `translateExpression(actualExpr)` straight into the call.
- `CppTranslator.kt:1137-1172`: an ordinary function or method call does the
  same and ends in `cpp.callExpr(callableExpr, translatedArgs)`.
- `RunCpp.kt:107` compiles with `-std=c++14`. Before C++17 the evaluations
  of function arguments are unsequenced; from C++17 they are indeterminately
  sequenced. Neither is left to right.

Braced initialization, `T{a, b}`, is evaluated left to right in C++11 and
later, but it does not apply to function calls. Evaluating each argument
that is not a constant or a local into a local before the call does.

The `classes/write-back-through-field` failure in #531, under x86-64 g++
14 on the C++ that upstream `ffba652a` generates for that test:

```
ping=1
pass=2
record=true most=0
around=29 n=3
```

`p.most` is read before `p.record()` runs and `p.n` before `p.around()`.
