# On rust, a promise resumes only the last async block that awaits it

Two `async` blocks await the same promise and a third completes it. On rust
only the second block resumes; the first never runs past its `await`, and the
program exits with status 0 and no warning. js, py, java, cpp and the
interpreter resume both blocks.

```
interp  completed | first waiter got 7 | second waiter got 7
js      completed | first waiter got 7 | second waiter got 7
cpp     completed | first waiter got 7 | second waiter got 7
py      first waiter got 7 | completed | second waiter got 7
java    completed | first waiter got 7 | second waiter got 7
rust    second waiter got 7 | completed
```

The rust line was the same in 20 of 20 runs of the built binary. py and java
start the blocks on a thread pool, so their order changes from run to run,
but both waiters printed in every run: 50 of 50 on py, 30 of 30 on java.

## Source

[`two-waiters/src/main.temper.md`](two-waiters/src/main.temper.md):

```temper
let pb = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let v = await pb.promise orelse -1;
  console.log("first waiter got ${v}");
}
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let v = await pb.promise orelse -1;
  console.log("second waiter got ${v}");
}
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  pb.complete(7);
  console.log("completed");
}
```

```sh
./repro.sh 07-promise-second-waiter-dropped/two-waiters rust
./repro.sh 07-promise-second-waiter-dropped/two-waiters js
./repro.sh 07-promise-second-waiter-dropped/two-waiters py
./repro.sh 07-promise-second-waiter-dropped/two-waiters cpp
./07-promise-second-waiter-dropped/run-java.sh
```

`run-java.sh` builds with the CLI and compiles with `javac`, because
`temper run -b java` on `e9ff0d25` stops on the JDK version string
`21.0.12.1`. The interpreter line comes from the REPL, fed the same source
on one line:

```sh
(sed -n 's/^    //p' 07-promise-second-waiter-dropped/two-waiters/src/main.temper.md \
  | sed 's/^}$/};/' | tr '\n' ' '; echo) | "$TEMPER" repl
```

## Output

rust:

```
second waiter got 7
completed
```

js:

```
completed
first waiter got 7
second waiter got 7
```

py (one run; the other order seen was `first`, `second`, `completed`):

```
first waiter got 7
completed
second waiter got 7
```

java (one run; the order varies, both waiters print every time):

```
completed
first waiter got 7
second waiter got 7
```

cpp:

```
completed
first waiter got 7
second waiter got 7
```

interpreter (REPL):

```
$ completed
first waiter got 7
second waiter got 7
interactive#0: void
```

## Expected

Every block that awaits a promise resumes once it settles, as on the other
five. The rust runtime keeps one listener per promise, so it would need a
list of them, drained when the promise completes or breaks.

## Notes

From reading the code at `e9ff0d25`:

The rust `Promise` holds a single task:
`be-rust/src/commonMain/resources/lang/temper/be/rust/temper-core/src/promise.rs:84-86`
reads `// Provide only one bonus listener for now. TODO Do we need more?`
above `next: Arc<RwLock<Option<Task>>>`. `on_ready` overwrites it at
`promise.rs:121`, so the second `await` replaces the first block's task, and
`next()` at `promise.rs:103-111` runs only the task left in the slot.

The interpreter keeps a list per promise (`fundamentals/src/commonMain/kotlin/lang/temper/value/Promises.kt:30`,
appended at `:72`) and moves the whole list to its ready queue on resolution
(`Promises.kt:51-53`). cpp keeps a vector, with a comment saying why:
`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/promise.hpp:56-58,83`.
py registers with `Future.add_done_callback`
(`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:1147`)
and java's generated code uses `CompletableFuture.handle`; both keep every
callback.

The functional test `control-flow/async` awaits one promise twice, but from
one block and after it has completed
(`functional-test-suite/src/commonMain/resources/control-flow/async/async.temper.md:49-53`).
On rust that path skips the slot, since `on_ready` runs the task at once
when the promise is already resolved (`promise.rs:119`). No test in the
suite has two blocks waiting at the same time.

The rust output also prints `second waiter got 7` before `completed`: the
waiter runs inside `complete()`. That is a separate divergence, case
[08-promise-complete-resumes-inline](../08-promise-complete-resumes-inline).

`breakPromise` goes through the same `next()` (`promise.rs:157`) and drops
the same waiter. With `pb.complete(7)` replaced by `pb.breakPromise()`, rust
prints `second waiter got -1` and `completed`; js prints all three lines.

Not checked: csharp (no `dotnet` here).
