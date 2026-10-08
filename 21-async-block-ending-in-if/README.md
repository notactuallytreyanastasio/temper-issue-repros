# An async block whose last statement is an `if`, after an `await`, puts a garbage statement in each branch on java, rust and cpp

The frontend reports `Cannot translate (Block)` once per branch, and the
backends that turn coroutines into state machines emit a broken statement
there. rust prints the branch's output and then panics; java prints it and
`temper run` reports failure; cpp does not build. js, py and the interpreter
print `pos`.

```temper
let p = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let v = await p.promise orelse -1;
  if (v < 0) { console.log("neg"); } else { console.log("pos"); }
}
p.complete(3);
```

```
[-work/src/main.temper.md:6+37-38]: Cannot translate (Block)
[-work/src/main.temper.md:6+66-67]: Cannot translate (Block)
```

rust (generated `src/mod.rs`, then the run):

```rust
4 => {
    if temper_core::read_locked( & self.v__3) < 0 {
        println!("{}", "neg");
        panic!("Unsupported: <garbage \"(Block)\">;");
    } else {
        println!("{}", "pos");
        panic!("Unsupported: <garbage \"(Block)\">;");
    }
    return None;
},
```

```
pos
thread 'main' panicked at src/mod.rs:86:29:
Unsupported: <garbage "(Block)">;
Run failed
```

java prints `pos`, then `Run failed`, exit 1. The generated Java has a
comment where the statement was:

```java
if (local$1.v__3 < 0) {
    console_4.log("neg");
    /* (Block) */
} else {
    console_4.log("pos");
    /* (Block) */
}
return DoneResult.get();
```

cpp: the two diagnostics, then `Run failed` with no output; `temper build -b cpp`
exits 1 (so do java and rust; js, py and lua exit 0).

The three libraries here:

| Library | Shape | js | py | interp | java | rust |
|---|---|---|---|---|---|---|
| [`if-else-after-await`](if-else-after-await/src/main.temper.md) | the program above | `pos` | `pos` | `pos` | `pos`, Run failed | `pos`, panic |
| [`if-after-await`](if-after-await/src/main.temper.md) | `if (v > 0) { ... }`, no `else` | `pos` | SyntaxError (see below) | `pos` | `pos`, Run failed | `pos`, panic |
| [`in-a-function`](in-a-function/src/main.temper.md) | the `async` block inside a function, the promise completed inside the block | `pos 3` | `pos 3` | `pos 3` | `pos 3`, Run failed | `pos 3`, panic |

The py failure on `if-after-await` is a different bug, not filed yet: py
fails to load any async block that ends in an `if` with no `else`, whether
or not it awaits, with `SyntaxError: no binding for nonlocal`.

```sh
./repro.sh 21-async-block-ending-in-if/if-else-after-await rust
./repro.sh 21-async-block-ending-in-if/if-else-after-await java
./repro.sh 21-async-block-ending-in-if/if-after-await rust
./repro.sh 21-async-block-ending-in-if/in-a-function rust
./repro.sh 21-async-block-ending-in-if/if-else-after-await js
```

java was run with JDK 27 first on `PATH` because of #525.

## Expected

`pos` (or `pos 3`) on every backend, with no diagnostic.

## Notes

The cause is in `CoroutineConverter`, not in the backends. Each branch of the
final `if` ends with `return__N = doneResult()`. The converter drops those
assignments, since the state machine writes its own `doneResult()` on every
terminal path, and it drops them with `freeTree(t)`
(`frontend/src/commonMain/kotlin/lang/temper/frontend/coroutine/CoroutineConverter.kt:578-580`),
which leaves an empty block where the tree was. The `if` does not yield but
something before it does, so the `if` is isolated as a sub-block and copied
into its case with the empty block inside. TmpL has no statement for a bare
block (`translateStatementOrExpression`,
`be/src/commonMain/kotlin/lang/temper/be/tmpl/TmpLTranslator.kt:1056`), so
each branch becomes garbage.

This is why nearby shapes pass. With a statement after the `if`, the return
assignment sits outside it. With no `await` before the `if`, nothing is
isolated.

The comment on that line says "Just `void` out returns". Replacing the
assignment with a `void` value leaf, as `maybeAdjustVars` already does for
hoisted declarations, fixes all three libraries here. With that change (a
local build of ffba652a plus the patch; [#543](https://github.com/temperlang/temper/pull/543)), java and rust print `pos`, `pos` and `pos 3` with no diagnostic,
and cpp builds all three and prints `pos 3` for `in-a-function`. cpp prints
nothing for the two top-level ones, which is #520. A new stage test,
`CoroutineConverterTest.awaitOrelseThenIf`, fails before the change and
passes after; the frontend's 704 tests pass.

Translating an empty block as no statement in TmpL would also make these
run, but it would hide the next placeholder that leaks the same way.

Not checked: csharp (no `dotnet` here). lua cannot run any of these: it
stops at `bad connected key: promisebuilder_constructor`.
