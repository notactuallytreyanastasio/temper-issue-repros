# PromiseBuilder.complete runs the waiting async block before it returns on rust, py and java

On rust, py and java, `complete()` resumes the `async` block that awaits the
promise inside the call, so the waiter prints before the line after
`complete()`. On js, cpp and the interpreter, `complete()` returns first and
the waiter runs after the completing block finishes.

```
interp  waiter: awaiting | completer: calling complete | completer: complete returned | waiter: resumed with 1
js      waiter: awaiting | completer: calling complete | completer: complete returned | waiter: resumed with 1
cpp     waiter: awaiting | completer: calling complete | completer: complete returned | waiter: resumed with 1
rust    waiter: awaiting | completer: calling complete | waiter: resumed with 1 | completer: complete returned
py      waiter: awaiting | completer: calling complete | waiter: resumed with 1 | completer: complete returned
java    waiter: awaiting | completer: calling complete | waiter: resumed with 1 | completer: complete returned
```

Each line was the same on every run: rust 20 of 20, py 30 of 30, java 30 of
30, js 5 of 5.

## Source

[`complete-then-log/src/main.temper.md`](complete-then-log/src/main.temper.md):

```temper
let pb = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("waiter: awaiting");
  let v = await pb.promise orelse -1;
  console.log("waiter: resumed with ${v}");
}
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  // py and java start both blocks at once on a thread pool.
  // Spinning here lets the waiter reach its await first.
  var spin = 0;
  while (spin < 5000000) { spin += 1; }
  console.log("completer: calling complete");
  pb.complete(1);
  console.log("completer: complete returned");
}
```

The spin loop is there for java. Without it, java often ran `complete()`
before the waiter had registered, and the order then shows nothing about
`complete()`. py showed the inline order in 50 of 50 runs without the loop.

```sh
./repro.sh 08-promise-complete-resumes-inline/complete-then-log rust
./repro.sh 08-promise-complete-resumes-inline/complete-then-log py
./repro.sh 08-promise-complete-resumes-inline/complete-then-log js
./repro.sh 08-promise-complete-resumes-inline/complete-then-log cpp
./08-promise-complete-resumes-inline/run-java.sh
```

`run-java.sh` builds with the CLI and compiles with `javac`, because
`temper run -b java` on `e9ff0d25` stops on the JDK version string
`21.0.12.1`. The interpreter line comes from the REPL, fed the source on one
line without the spin loop: the REPL stops a 5,000,000 step loop with
`Interpretation aborted`, and it runs one block at a time anyway.

```sh
(sed -n 's/^    //p' 08-promise-complete-resumes-inline/complete-then-log/src/main.temper.md \
  | grep -v '//\|spin' | sed 's/^}$/};/' | tr '\n' ' '; echo) | "$TEMPER" repl
```

## Output

rust, py and java:

```
waiter: awaiting
completer: calling complete
waiter: resumed with 1
completer: complete returned
```

js and cpp:

```
waiter: awaiting
completer: calling complete
completer: complete returned
waiter: resumed with 1
```

interpreter (REPL):

```
$ waiter: awaiting
completer: calling complete
completer: complete returned
waiter: resumed with 1
interactive#0: void
```

## Expected

One order on every backend. The doc comments on `Promise` and
`PromiseBuilder` (`frontend/src/commonMain/resources/core/core.temper:319-354`)
do not say which. The
interpreter queues the waiter and runs it after the completing block yields,
as js and cpp do, so that is the reference this case measures against.

With the inline order, code after `complete()` runs after the waiter has
already acted. A method that completes a promise halfway through can have a
waiter call back into the same object while the method is still running.
That consequence is from reading, not from a program here.

## Notes

From reading the code at `e9ff0d25`:

The interpreter's `Promises.resolve` moves the awaiters to a FIFO ready
queue and returns (`fundamentals/src/commonMain/kotlin/lang/temper/value/Promises.kt:44-57`);
the run loop takes them off that queue later
(`interp/src/commonMain/kotlin/lang/temper/interp/Interpreter.kt:241-242`).
cpp does the same: `PromiseState::settle` enqueues each continuation
(`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/promise.hpp:63-69`).
js resolves a native `Promise` (`be-js/src/commonMain/resources/lang/temper/be/js/temper-core/async.js:60-62`),
whose `then` callbacks run as microtasks after the current code.

rust calls the stored task directly:
`PromiseBuilder::complete` calls `self.promise().next()`
(`be-rust/src/commonMain/resources/lang/temper/be/rust/temper-core/src/promise.rs:161-172`),
and `next()` runs it on the spot (`promise.rs:103-111`). `on_ready` also runs
the task inline when the promise has already resolved (`promise.rs:119`).

py completes a `concurrent.futures.Future` with `set_result`
(`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:1206-1215`).
`Future.set_result` calls the done callbacks in the calling thread
(CPython 3.14 `concurrent/futures/_base.py:536-549`), and the callback steps
the waiting generator (`__init__.py:1144-1147`).

java registers the waiter with `CompletableFuture.handle`, in the generated
code:

```java
local$1.awaited_34.handle((ignored$1, ignored$2) -> {
        generator_35.get();
        return null;
});
```

and the completing block calls `pb__0.complete(1)`. The output shows the
waiter running inside that call.

The functional test `control-flow/async` has a block that completes a
promise another block awaits, but it logs nothing after `complete()`
(`functional-test-suite/src/commonMain/resources/control-flow/async/async.temper.md:75-78`),
so it passes with either order.

Not checked: csharp (no `dotnet` here).
