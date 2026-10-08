# A generator's `done`, `is ValueResult`, and `nextSafe()` at the end work on few backends

`core.temper` gives `Generator` a `done` property and has `nextSafe()`
return a `GeneratorResult`, which is a `ValueResult` holding the yielded
value or a `DoneResult`. Asking for any of that breaks on most backends.

[`done`](done/src/main.temper.md) reads `g.done` before and after each step:

```temper
let gen(body: fn (): SafeGenerator<Empty>): SafeGenerator<Empty> { body() }

let g = gen { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("step");
  yield;
  console.log("last step");
};
console.log("before: ${g.done}");
g.nextSafe();
console.log("after one: ${g.done}");
g.nextSafe();
console.log("after two: ${g.done}");
```

[`value-result`](value-result/src/main.temper.md) yields 10 and 20 and
tests each result with `when (r) { is ValueResult<Int> -> ... }`.

[`next-at-end`](next-at-end/src/main.temper.md) calls `nextSafe()` three
times on a generator with two steps.

| Backend | `done` | `value-result` | `next-at-end` |
|---|---|---|---|
| rust | `before: false`, `step`, `after one: false`, `last step`, `after two: true` | translator: `NotImplementedError: An operation is not implemented: ValueResult` | expected output |
| js | `TypeError: Cannot read properties of undefined (reading 'toString')`: `g.done` is `undefined` | `ReferenceError: ValueResult_6 is not defined` | expected output |
| py | `AttributeError: 'generator' object has no attribute 'done'` | `NameError: name '_value_result' is not defined` | `first step`, `one call`, `last step`, then `StopIteration` |
| cpp | `error: no member named 'get_done' in 'temper::core::SafeGenerator<...>'` | `error: no matching function for call to 'dynamic_pointer_cast'` | expected output |
| java (`javac`) | `error: cannot find symbol` `isDone()` on `Generator` | `error: cannot find symbol` `getValue()` on `ValueResult` | expected output |

java cannot run under `temper run` here because of
[#525](https://github.com/temperlang/temper/issues/525); its column is
`javac` on the generated sources, and for `next-at-end` the compiled
classes run with `java -cp`.

```sh
./repro.sh 55-generator-done-and-value-result/done js
./repro.sh 55-generator-done-and-value-result/done py
./repro.sh 55-generator-done-and-value-result/value-result rust
./repro.sh 55-generator-done-and-value-result/next-at-end py
```

## Expected

On every backend, `done` prints `before: false`, `step`, `after one:
false`, `last step`, `after two: true` (as rust does, and as `core.temper`
documents: `done` may stay false after the last yield until the next call
finds the body finished); `value-result` prints `value 10`, `value 20`,
`no value`; `next-at-end` prints all five lines.

## Notes

From reading the code at ffba652a. py maps `Generator.next()`,
`SafeGenerator.next()` and `SafeGenerator.nextSafe()` to Python's builtin
`next` (`be-py/src/commonMain/kotlin/lang/temper/be/py/PySupportNetwork.kt:896`,
`:1134`, `:1210-1211`), so a call returns the raw yielded value instead of a
`ValueResult`, raises `StopIteration` when the body finishes instead of
returning a `DoneResult`, and the generator is a Python generator, which has
no `done`. js maps `nextSafe()` through `nextIdiomExpander`
(`be-js/src/commonMain/kotlin/lang/temper/be/js/JsSupportNetwork.kt:253`)
and no generator object it makes has a `done` property. rust represents a
`ValueResult` as `Some` (`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustSupportNetwork.kt:1147`),
and its translator has no case for a type test against it.

None of the functional tests reads `done` or tests a result's type, which
is how these went unnoticed. Found while writing be-piet, which represents
a generator as `[step function, done]`, a `ValueResult` as a box and a
`DoneResult` as null, and prints the expected output for all three cases.
