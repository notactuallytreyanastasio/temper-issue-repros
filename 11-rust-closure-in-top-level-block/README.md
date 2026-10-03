# rust: a function or async block inside a top-level `if` or `while` cannot read a top-level variable

When a module-level variable is read by a function declared inside a
top-level block, such as the body of an `if` or a `while`, the rust backend
leaves the variable as a local of the module's `init` closure and turns the
function into an `fn` item that names it. rustc rejects that with E0434. js
and py run the same library and print the expected value.

An `async { }` block counts as such a function, so an `async` block started
in a top-level loop hits this too. That is how it was found.

## Source

[`if-block/src/main.temper.md`](if-block/src/main.temper.md):

```temper
var n = 1;
n += 1;
if (n > 0) {
  let f(): Void { console.log("n=${n}"); }
  f();
}
```

[`async-in-while/src/main.temper.md`](async-in-while/src/main.temper.md):

```temper
var n = 0;
var t = 0;
while (t < 2) {
  async { (): GeneratorResult<Empty> extends GeneratorFn =>
    n += 1;
    console.log("n=${n}");
  }
  t += 1;
}
```

```sh
./repro.sh 11-rust-closure-in-top-level-block/if-block rust
./repro.sh 11-rust-closure-in-top-level-block/if-block js
./repro.sh 11-rust-closure-in-top-level-block/async-in-while rust
./repro.sh 11-rust-closure-in-top-level-block/no-block rust
```

## Output

`if-block` on rust, from cargo, after which the CLI prints `Run failed` and
exits 1:

```
error[E0434]: can't capture dynamic environment in a fn item
  --> src/mod.rs:16:42
   |
16 |                         println!("n={}", n__1);
   |                                          ^^^^
   |
   = help: use the `|| { ... }` closure form instead

For more information about this error, try `rustc --explain E0434`.
error: could not compile `if-block` (lib) due to 1 previous error
```

`if-block` on js and py:

```
n=2
```

`async-in-while` fails on rust with the same error three times, at each use
of `n` (`src/mod.rs:28:37`, `28:44` and `29:54`). On js and py it prints:

```
n=1
n=2
```

## What the backend writes

`temper.out/rust/if-block/src/mod.rs`:

```rust
pub (crate) fn init() -> temper_core::Result<()> {
    static INIT_ONCE: std::sync::OnceLock<temper_core::Result<()>> = std::sync::OnceLock::new();
    INIT_ONCE.get_or_init(| |{
            let mut n__1: i32 = 1;
            n__1 = n__1.wrapping_add(1);
            if n__1 > 0 {
                #[derive(Clone)]
                struct ClosureGroup___1 {}
                impl ClosureGroup___1 {
                    fn f__2(& self) {
                        println!("n={}", n__1);
                    }
                }
                let closure_group = ClosureGroup___1 {};
                let f__2 = {
                    let closure_group = closure_group.clone();
                    std::sync::Arc::new(move | | closure_group.f__2())
                };
                f__2();
            }
            Ok(())
    }).clone()
}
```

`ClosureGroup___1` is empty, so `n__1` is neither captured nor a module
`static`. In `async-in-while` the same empty `ClosureGroup___1` holds the
async block's `fn__7`, and the update `n__0 = n__0.wrapping_add(1)` sits two
`fn` items down.

The control library [`no-block`](no-block/src/main.temper.md) has the same
`f` outside any block. It runs on rust and prints `n=2`, because there `n`
becomes `static N: std::sync::RwLock<Option<i32>>` and `f__1` reads it
through `n()`.

## What decides it

From reading the code in `be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustTranslator.kt`
at `e9ff0d25`:

`preprocessTopLevels` (lines 288 to 333) promotes a module-level variable
to a `static` ("topper", line 315) only when it is referenced from a
`ModuleFunctionDeclaration` or a `TypeDeclaration` (line 306). Every other
top level, including the module init block that holds the `if`, is skipped
at line 308.

`translateLocalFunctionDeclarations` (lines 2483 onward) builds the closure
group from referenced names whose `DeclInfo` has `local = true` (line 2503).
Module-level declarations are registered with `local = false` (line 297).

A module-level variable read only from a local function in a top-level
block is therefore neither a `static` nor a capture.

## Shapes checked

All on `e9ff0d25`, rust backend:

| Shape | rust |
|---|---|
| reassigned `var`, function in top-level `if` | E0434 |
| `var` updated in `async` block in top-level `while` | E0434 |
| `var` only read, `async` block in top-level `while` | E0434 |
| `var` updated in `async` block in top-level `if` | E0434 |
| `var` updated in `async` block in top-level `for` | E0434 |
| `let s = "abc".split("")`, function in top-level `if` | E0434 |
| `var` updated in a lambda added to a list in top-level `while` | E0434, plus an unrelated E0618 |
| same function at top level, no block (`no-block`) | runs |
| same function in `do { }` at top level | runs |
| same `if` and function inside a function body | runs |
| `var n = 1` never reassigned, function in top-level `if` | runs |
| `let n = 5`, `async` block in top-level `while` | runs |
| `let n = 5`, `async` block in top-level `for` | runs |

The last two run because the value is constant; the generated code does not
read a variable at all there. Rows without a library in this directory were
run as separate probes and are not kept here.

## Expected

The program prints `n=2` on rust, as it does on js and py. Either
`preprocessTopLevels` treats references from local functions anywhere in the
module init as top-level references, or the closure group captures
module-level declarations that stay local to `init`.

## Notes

[#328](https://github.com/temperlang/temper/issues/328), fixed by #330, was
E0434 from `fn` items emitted for `when` branches inside a function body.
[#223](https://github.com/temperlang/temper/issues/223) (open) is a closure
in a conditional inside a function that assigns a capture without wrapping
it. Neither covers module-level variables. Not checked: backends other than
js and py.
