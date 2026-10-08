# A `List<Square>` used where `List<Shape>` is expected passes the frontend, then fails to compile on java and rust, and on cpp when it is a returned literal

Temper lets a `List` of a subtype stand in for a `List` of its supertype.
The java, rust and cpp backends emit their own list types for it, which are
invariant, and do not always convert.

[`shapes`](shapes/src/main.temper.md) passes a variable:

```temper
export interface Shape { area(): Int; }
export class Square(public side: Int) extends Shape {
  public area(): Int { side * side }
}

export let total(shapes: List<Shape>): Int {
  var sum = 0;
  for (let s of shapes) { sum += s.area(); }
  sum
}

let squares: List<Square> = [new Square(2), new Square(3)];
console.log(total(squares).toString());
```

java (`temper.out/java/maven.log`):

```
[ERROR] .../ShapesGlobal.java:[27,60] incompatible types: java.util.List<shapes.Square> cannot be converted to java.util.List<shapes.Shape>
```

rust:

```
error[E0277]: the trait bound `Arc<Vec<Square>>: ToList<Shape>` is not satisfied
   --> src/mod.rs:10:34
    |
 10 |             println!("{}", total(squares__7.clone()));
    |                            ----- ^^^^^^^^^^^^^^^^^^ the trait `ToList<Shape>` is not implemented for `Arc<Vec<Square>>`
    |                            |
    |                            required by a bound introduced by this call
    |
help: the trait `ToList<Shape>` is not implemented for `Arc<Vec<Square>>`
      but trait `ToList<Square>` is implemented for it
```

cpp converts here, `total(temper::core::List::upcast<std::shared_ptr<Shape>>(squares))`,
and prints `13`, as do js, py and lua.

[`literal`](literal/src/main.temper.md) returns a literal:

```temper
export let squares(n: Int): List<Shape> { [new Square(n), new Square(n + 1)] }
```

This time java prints `13`, and rust and cpp fail:

```
error[E0308]: mismatched types
  --> src/mod.rs:71:37
   |
71 |     return std::sync::Arc::new(vec![Square::new(n__15), Square::new(n__15.wrapping_add(1))]);
   |                                     ^^^^^^^^^^^^^^^^^^ expected `Shape`, found `Square`
```

```
init.cpp:23:12: error: no viable conversion from returned value of type 'shared_ptr<vector<shared_ptr<literal::Square>>>' to function return type 'shared_ptr<vector<shared_ptr<Shape>>>'
```

```cpp
  std::shared_ptr<std::vector<std::shared_ptr<Shape>>> squares(int32_t n) {
    return temper::core::List::make<std::shared_ptr<Square>>(Square::make(n), Square::make(temper::core::Int::add(n, 1)));
  }
```

js, py and lua print `13`. A top-level
`let shapes: List<Shape> = [new Square(2), new Square(3)];` fails the same
way on rust (`expected Shape, found Square`) and cpp (`no viable overloaded
'='`), and runs on java. A literal passed straight to a `List<Shape>`
parameter, `total([new Square(2), new Square(3)])`, compiles on java, rust
and cpp, and so does `new Sequence([Begin, new CodePoints("x")])` with
mixed element types. So the frontend seems to type the literal from its
context only in some positions.

This came up with std/regex ([`regex`](regex/src/main.temper.md)):
`new Sequence(parts)` with `parts: List<CodePoints>`, where `Sequence`
takes `List<RegexNode>`. js, py and lua print `true`; java reports
`java.util.List<temper.std.regex.CodePoints> cannot be converted to java.util.List<temper.std.regex.RegexNode>`
and rust `the trait bound Arc<Vec<CodePoints>>: ToList<RegexNode> is not satisfied`.
On cpp that program compiles and then crashes with a segfault, for an
unrelated reason: a module that imports only classes from std/regex never
calls `temper_std::global_init_regex()`.

## Expected

Each backend converts where its list type is invariant, as cpp already does
for call arguments, or the frontend rejects the program on every backend.

## Notes

cpp has `wrapWithListUpcastIfNeeded`
(`be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppTranslator.kt:316`),
called for call arguments (line 357), assignments (1410) and local
initializers (1497). A `return` does not go through it, which fits the
`literal` failure; the top-level `let` failing is not explained by that,
and I did not trace it. I found no counterpart in be-java or be-rust (from
a search for "upcast" and for list conversions; not exhaustive). The rust
parameter type `impl temper_core::ToList<Shape>` has an impl only for
`List<T>` to `ToList<T>` (`temper-core/src/listed.rs:290`).

#294 and #295 are about covariant return types (`ListBuilder<Int>` for
`Listed<Int>`) on csharp and rust; this is element-type covariance and a
different code path, as far as I can tell. csharp was not run.
