# rust: an `Int64` literal outside the `i32` range, cast with `toInt32Unsafe()` or `toFloat64Unsafe()`, is emitted without a suffix and rustc rejects it

```temper
let k = 0xb5c0fbcfi64.toInt32Unsafe();
console.log(k.toString());
```

The rust backend writes the literal with no type suffix in front of the
cast:

```rust
            let k__0: i32 = 3049323471 as i32;
```

An unsuffixed literal there is typed `i32`, so rustc reports it as out of
range:

```
$ ./repro.sh 42-rust-int64-literal-cast/narrowing rust
error: literal out of range for `i32`
 --> src/mod.rs:9:29
  |
9 |             let k__0: i32 = 3049323471 as i32;
  |                             ^^^^^^^^^^
  |
  = note: the literal `3049323471` does not fit into the type `i32` whose range is `-2147483648..=2147483647`
  = help: consider using the type `u32` instead
  = note: `#[deny(overflowing_literals)]` on by default
```

`toFloat64Unsafe()` fails the same way
([`floating`](floating/src/main.temper.md)):

```temper
let f = 9007199254740993i64.toFloat64Unsafe();
```

```
error: literal out of range for `i32`
 --> src/mod.rs:9:29
  |
9 |             let f__0: f64 = 9007199254740993 as f64;
  |                             ^^^^^^^^^^^^^^^^
```

js, py, java, cpp and lua print `-1245643825` for `narrowing`, and
`9007199254740992.0` for `floating` (java prints `9.007199254740992e+15`).

A function `narrow(x: Int64): Int { x.toInt32Unsafe() }` translates to
`x__3 as i32`, which compiles, and a call `narrow(0xb5c0fbcfi64)` is folded
to `-1245643825` before it reaches the backend. So it takes a literal as the
direct receiver of the cast.

## Expected

`3049323471i64 as i32` (and `9007199254740993i64 as f64`), and the same
output as the other backends.

## Notes

From reading `be-rust/src/commonMain/kotlin/lang/temper/be/rust/`: the
casts are `Cast` support codes (`RustSupportNetwork.kt:298`), which emit
`arguments[0].expr as <type>` (line 304), with `Int64ToInt32Unsafe` at line
871 and `Int64ToFloat64Unsafe` at 867. The literal comes from
`translateValueReference` as `Rust.NumberLiteral(pos, TInt64.unpack(...))`
(`RustTranslator.kt:3415`), which carries no `i64` suffix. In most
positions the declared type around it fixes the literal's type, but as the
left operand of `as` nothing does. Suffixing `Int64` literals, or
suffixing in `Cast` when the operand is a literal, would cover both.
