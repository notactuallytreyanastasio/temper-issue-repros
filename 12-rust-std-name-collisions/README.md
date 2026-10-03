# rust: a class named `Box`, `Option`, `Some`, `None`, `Ok` or `Err` shadows the Rust prelude and the output does not compile

The rust backend emits a Temper class under its own name, and it escapes only
Rust keywords. Generated code and the `temper_core::impl_any_value_trait!`
macro then write `Box`, `Option`, `Some`, `None`, `Ok` and `Err` unqualified,
so a user class with one of those names takes their place and cargo fails.
js and py run the same libraries.

## Source

[`class-box/src/main.temper.md`](class-box/src/main.temper.md):

```temper
class Box(public n: Int) {}
console.log("n=${new Box(1).n}");
```

`class-option`, `class-some`, `class-none` and `class-ok` are the same two
lines with the class renamed. [`class-err`](class-err/src/main.temper.md)
also needs a function that bubbles, since that is where `Err(...)` is
emitted:

```temper
class Err(public n: Int) {}
let half(x: Int): Int throws Bubble {
  if (x % 2 != 0) { bubble(); }
  return x / 2;
}
console.log("n=${new Err(1).n} half=${half(4) orelse -1}");
```

```sh
./repro.sh 12-rust-std-name-collisions/class-box rust
./repro.sh 12-rust-std-name-collisions/class-box js
./repro.sh 12-rust-std-name-collisions/class-err rust
./repro.sh 12-rust-std-name-collisions/class-vec rust
```

## Output

`class-box` on rust, from cargo, after which the CLI prints `Run failed` and
exits 1 (the `help:` block of the second error is cut):

```
error[E0107]: struct takes 0 generic arguments but 1 generic argument was supplied
  --> src/mod.rs:31:1
   |
31 | temper_core::impl_any_value_trait!(Box, []);
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   | |
   | expected 0 generic arguments
   | help: remove the unnecessary generics
   |
note: struct defined here, with 0 generic parameters
  --> src/mod.rs:17:20
   |
17 | pub (crate) struct Box(std::sync::Arc<BoxStruct>);
   |                    ^^^
   = note: this error originates in the macro `temper_core::impl_any_value_trait` (in Nightly builds, run with -Z macro-backtrace for more info)

error[E0053]: method `cast` has an incompatible type for trait
  --> src/mod.rs:31:1
   |
31 | temper_core::impl_any_value_trait!(Box, []);
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ expected `std::boxed::Box<(dyn Any + 'static)>`, found `r#mod::Box`
   |
   = note: expected signature `fn(&r#mod::Box, TypeId) -> Option<std::boxed::Box<(dyn Any + 'static)>>`
              found signature `fn(&r#mod::Box, TypeId) -> Option<r#mod::Box>`
   = note: this error originates in the macro `temper_core::impl_any_value_trait` (in Nightly builds, run with -Z macro-backtrace for more info)
...

error[E0308]: mismatched types
  --> src/mod.rs:31:1
   |
31 | temper_core::impl_any_value_trait!(Box, []);
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   | |
   | expected `i32`, found `Box`
   | arguments to this function are incorrect
   |
note: associated function defined here
  --> src/mod.rs:19:12
   |
19 |     pub fn new(n__5: i32) -> Box {
   |            ^^^ ---------
   = note: this error originates in the macro `temper_core::impl_any_value_trait` (in Nightly builds, run with -Z macro-backtrace for more info)

Some errors have detailed explanations: E0053, E0107, E0308.
For more information about an error, try `rustc --explain E0053`.
error: could not compile `class-box` (lib) due to 3 previous errors
```

`class-err` on rust:

```
error[E0308]: mismatched types
  --> src/mod.rs:36:16
   |
33 | fn half__4(x__8: i32) -> temper_core::Result<i32> {
   |                          ------------------------ expected `Result<i32, temper_core::Error>` because of return type
...
36 |         return Err(temper_core::Error::new());
   |                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ expected `Result<i32, Error>`, found `Err`
   |
   = note: expected enum `Result<i32, temper_core::Error>`
            found struct `r#mod::Err`
```

On js and py every library here runs and prints `n=1`, or `n=1 half=2` for
`class-err`.

## Each name

| Library | rust | Where the name is used unqualified |
|---|---|---|
| `class-box` | 3 errors | `Box` in the macro, `src/mod.rs:31` |
| `class-option` | 5 errors | `Option` in the macro, and in `pub fn init(config: Option<...>)` in the generated `src/lib.rs:7`, which has `pub use r#mod::*;` |
| `class-some` | 2 errors | `Some(...)` in the macro |
| `class-none` | 1 error | `None` in the macro |
| `class-ok` | 2 errors | `Ok(())` at the end of the module's `init`, `src/mod.rs:10` |
| `class-err` | 2 errors | `Err(...)` in the bubbling function, `src/mod.rs:36` |
| `class-vec` | runs, `n=2 half=2` | control |

These ran without error as class names, in separate probes not kept here:
`Vec`, `Result`, `Arc`, `Any`, `Clone` and `Default` in the two-line
program, and `Vec`, `Result` and `Arc` again with string lists and a
bubbling function. Generated code writes `std::sync::Arc`,
`temper_core::Result` and `temper_core::List`, so those names are
qualified where it emits them. `String` could not be tried: a class named
`String` is rejected by the Temper frontend before the backend runs.

## Where the names come from

From reading the code at `e9ff0d25`:

The class name is the Temper name as written:
`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustTranslator.kt:3302`,
`translateTypeOutName(name) = OutName(name.displayName, name)`, used for the
struct at line 693.

The only reserved list is `keys` in
`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustExt.kt:755`, the
Rust keywords, which `OutName.escape()` (line 169) turns into raw
identifiers such as `r#match`. It has lowercase `box` but no prelude names.

The unqualified uses: the `impl_any_value_trait` macro in
`be-rust/src/commonMain/resources/lang/temper/be/rust/temper-core/src/lib.rs:39,42,45,48`
writes `Option<Box<dyn std::any::Any>>`, `Some(Box::new(...))` and `None`;
a `macro_rules!` body resolves those at the call site, in the user's
module. `RustExt.kt:374,376,382` build `Ok(...)`, `Err(...)` and
`Some(...)` calls, and `RustTranslator.kt:3654` has
`OPTION_NAME = "Option"`, next to `RESULT_NAME = "temper_core::Result"`.

## Expected

A class named `Box` or `Ok` works on rust as it does on js and py. Either
the backend renames user types that collide with prelude names, or every
name it emits and every name in the macro is fully qualified
(`std::boxed::Box`, `std::option::Option::Some`,
`std::result::Result::Ok`, and so on).

## Notes

No issue in temperlang/temper reports this for rust. The closest is
[#250](https://github.com/temperlang/temper/issues/250) (open), a class
named `Type` that breaks the py and java backends. Not checked:
interfaces, enums, functions or module-level values with these names, and
other prelude names such as `Send`, `Sync`, `Iterator` or `ToString`.
