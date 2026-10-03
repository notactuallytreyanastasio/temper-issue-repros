# On cpp, an async block never resumes when top-level code completes the promise it awaits

The generated C++ `main()` calls the library's init function and returns.
Nothing runs the queue of continuations after that, so a block that awaits a
promise completed by top-level code never prints `resumed`, and the program
exits 0 with no message:

```
cpp     waiting | top level done
js      top level done | waiting | resumed
rust    top level done | waiting | resumed
py      waiting | resumed | top level done
interp  top level done | waiting | resumed
```

## Source

[`late-complete/src/main.temper.md`](late-complete/src/main.temper.md):

```temper
let g = new PromiseBuilder<Empty>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("waiting");
  await g.promise orelse void;
  console.log("resumed");
}
g.complete(empty());
console.log("top level done");
```

```sh
./repro.sh 09-cpp-continuation-never-resumes/late-complete cpp
./repro.sh 09-cpp-continuation-never-resumes/late-complete js
```

## Output

cpp, exit code 0:

```
waiting
top level done
```

js and rust, exit code 0:

```
top level done
waiting
resumed
```

py, exit code 0:

```
waiting
resumed
top level done
```

The interpreter line above comes from pasting the same statements on one
line into `temper repl`, which printed `top level done`, `waiting`,
`resumed`.

## What the cpp build writes

`temper.out/cpp/late-complete/main.cpp`:

```cpp
#include "late-complete/init.hpp"
int main() {
  late_complete::global_init_init();
}
```

and the end of `global_init_init` in `init.cpp`:

```cpp
    temper::core::async_run(fn);
    temper::core::complete(g, temper::core::empty());
    temper::core::Console::log(console_0, "top level done");
```

`async_run` queues the block and drains the queue at once. The block prints
`waiting`, registers its continuation on `g` and returns. `complete` then
moves that continuation onto the queue, and no code drains the queue again.

Adding one line to the generated `main.cpp` and compiling it with
`clang++ -std=c++20 -I.` prints `resumed`:

```cpp
int main() {
  late_complete::global_init_init();
  temper::core::async_drain();
}
```

```
waiting
top level done
resumed
```

## Expected

The block resumes and prints `resumed` before the program exits, as on js,
rust, py and the interpreter. A drain after the init calls in `main()` does
that for this case. I have not checked how it interacts with the test path,
where `main()` returns `run_tests(...)`.

## Notes

In upstream `e9ff0d25`:

- `be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppBackend.kt:197-200`
  emits `int main() {` and one call per init function, and nothing after
  them except the test harness when the library has tests.
- `be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/promise.hpp:161-165`:
  `async_run` is the only caller of `async_drain` (`:34`). `complete`
  (`:114-119`) and `breakpromise` (`:123-129`) call `settle` (`:63-67`), which
  only enqueues.

The functional test `control-flow/async/async.temper.md` passes on cpp
(`functional-test-matrix.md:23`) and would not catch this: the whole test
runs inside one `async` block, so every `complete` happens while
`async_drain` is already running and the loop picks up the continuation.
No functional test completes a promise from top-level code.

With the drain added, cpp still prints `waiting` before `top level done`,
because `async_run` runs the block before returning. js, rust and the
interpreter print `top level done` first. That ordering difference is
separate from this issue; #516 records a similar one on py.
