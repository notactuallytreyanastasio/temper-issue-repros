# rust: `v as T` on a nullable `v`, in a function returning `T? throws Bubble`, emits `return Some(Err(..))`, which does not compile

```temper
export sealed interface Node {}
export class Text(public s: String) extends Node {}
export class Num(public n: Int) extends Node {}

export let asText(v: Node?): Text? throws Bubble {
  if (v == null) { return null; }
  v as Text
}

let describe(v: Node?): String throws Bubble {
  let t = asText(v);
  if (t == null) { "null" } else { t.s }
}

console.log(describe(new Text("hi")) orelse "bubbled");
console.log(describe(null) orelse "bubbled");
console.log(describe(new Num(1)) orelse "bubbled");
```

The rust backend translates the cast's null branch to a bubble wrapped in
`Some`:

```rust
pub fn as_text(v__14: Option<Node>) -> temper_core::Result<Option<Text>> {
    let return__5: Option<Text>;
    'fn__15: {
        if v__14.is_none() {
            return__5 = None;
            break 'fn__15;
        }
        if v__14.is_none() {
            return Some(Err(temper_core::Error::new()));
        } else {
            ...
```

```
$ ./repro.sh 41-rust-failed-cast-in-nullable-return/nullable rust
error[E0308]: mismatched types
   --> src/mod.rs:132:20
    |
124 | pub fn as_text(v__14: Option<Node>) -> temper_core::Result<Option<Text>> {
    |                                        --------------------------------- expected `Result<Option<Text>, temper_core::Error>` because of return type
...
132 |             return Some(Err(temper_core::Error::new()));
    |                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ expected `Result<Option<Text>, Error>`, found `Option<Result<_, Error>>`
```

js and py run it:

```
$ ./repro.sh 41-rust-failed-cast-in-nullable-return/nullable js
hi
null
bubbled
$ ./repro.sh 41-rust-failed-cast-in-nullable-return/nullable py
hi
null
bubbled
```

It takes both nullables. These two functions build, and `cargo build`
accepts the output:

```temper
export let a(v: Node): Text? throws Bubble { v as Text }
export let b(v: Node?): Text throws Bubble { v as Text }
```

`b` gets the same null branch, written correctly as
`return Err(temper_core::Error::new());`.

## Expected

`return Err(temper_core::Error::new());` in `as_text` too, and the three
lines above.

## Notes

From reading `be-rust` at upstream main, not traced in a debugger: the
bubble is built by `translateBubbleSentinel` as
`Err(makeError(pos))` (`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustTranslator.kt:1733`).
The value adapter in `RustExt.kt:286` wraps any non-nullable value going to
a nullable wanted type in `Some`
(`!given.nullable && wanted.nullable -> result.wrapSome()`). The sentinel
appears to reach that adapter with the function's return type `Text?` as
the wanted type, so it gets wrapped as if it were the returned value. The
`v == null` check in `asText` is not needed for the failure; it is there
because that is how the cast is usually guarded.
