# A `continue` or `break` in a generator's loop loses its target on java, rust and cpp

A generator whose loop has a `continue` or `break` in a block that does not
yield fails to compile on java and rust, and on cpp either fails to compile
or builds a program that dies with no output. js and py, which keep their
generators native, print the expected lines.

```temper
let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }

let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
  for (var i = 0; i < 3; i += 1) {
    if (i == 1) { console.log("skip ${i}"); continue; }
    console.log("yield ${i}");
    yield();
  }
  console.log("done");
};
g.nextSafe();
g.nextSafe();
g.nextSafe();
```

js prints `yield 0`, `skip 1`, `yield 2`, `done`. The other backends:

rust:

```
error[E0426]: use of undeclared label `'continue___12`
  --> src/mod.rs:57:35
57 | ...                   break 'continue___12;
```

cpp:

```
init.cpp:42:24: error: use of undeclared label 'continue_5_end'
   42 |                   goto continue_5_end;
```

java (`temper run -b java` cannot run here because of
[#525](https://github.com/temperlang/temper/issues/525); this is `javac`
on the generated sources):

```
ContinueInLoopGlobal.java:50: error: undefined label: continue_12
                            break continue_12;
```

A `break` fails differently, because the loop it leaves is the state
machine's own `loop`. [`break-in-loop`](break-in-loop/src/main.temper.md)
and [`break-after-yield`](break-after-yield/src/main.temper.md), where
the `break` comes right after a bare `yield`:

| Backend | `continue-in-loop` | `break-in-loop` | `break-after-yield` |
|---|---|---|---|
| js | expected output | expected output | expected output |
| rust | `E0426` undeclared label | `E0308` mismatched types: `break;` where `Option<()>` is expected | same as `break-in-loop` |
| cpp | undeclared label `continue_5_end` | builds; exits 133 with no output | same as `break-in-loop` |
| java (`javac`) | `undefined label: continue_12` | `bad return type in lambda expression` | same as `break-in-loop` |

py prints the expected lines for all three, then raises `StopIteration` on
the call where the generator finishes; that is
[`55-generator-done-and-value-result`](../55-generator-done-and-value-result).

```sh
./repro.sh 54-generator-continue-loses-target/continue-in-loop rust
./repro.sh 54-generator-continue-loses-target/continue-in-loop cpp
./repro.sh 54-generator-continue-loses-target/break-in-loop rust
./repro.sh 54-generator-continue-loses-target/break-in-loop cpp
./repro.sh 54-generator-continue-loses-target/break-after-yield cpp
```

## Expected

The same lines as js on every backend.

## Notes

java, rust and cpp take `CoroutineStrategy.TranslateToRegularFunction`:
the frontend rewrites a generator body into a step function that switches
on a case index. Before that, `isolateNonYieldingSubtrees` in
`frontend/src/commonMain/kotlin/lang/temper/frontend/coroutine/CoroutineConverter.kt`
moves each sub-block that does not yield out of the state machine, intact.
The `if (i == 1) { ...; continue; }` block does not yield, so it is moved
out with its jump to the `for` body's `continue#N` label; the state machine
then dissolves that label into cases, and the jump is left with no target.
Each backend renders the targetless jump its own way, above.

The fix keeps a sub-block in place when it contains a `break` or `continue`
whose destination is outside it, so the jump becomes a case transition.
With it, all three cases print the js output on rust, cpp and java (java
run from the `javac` output with `java -cp`), and `:frontend:jvmTest` passes
705 of 705.

Found by two backends that are not upstream, each with its own state
machine runtime: be-elixir, where the step function fell off its end and
the generator stopped early without an error, and be-piet, which fails the
build with `no jump target for continue#20`.
