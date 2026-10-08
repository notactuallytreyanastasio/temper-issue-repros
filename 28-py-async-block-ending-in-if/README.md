# py: an async block whose last statement is an `if` with no `else` fails to load with `no binding for nonlocal`

```temper
var n = 3;
n = n + 0;
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  if (n > 0) { console.log("pos"); }
}
```

```
    nonlocal return_1
    ^^^^^^^^^^^^^^^^^
SyntaxError: no binding for nonlocal 'return_1' found
Run failed
```

js prints `pos`. The generated Python keeps the generator's done-result
assignment in a synthesized `else`, and declares the return variable
`nonlocal` though nothing binds it; `done_result` and `empty` are not
imported either:

```python
@adapt_generator_factory6
def _fn(do_await_7) -> 'Generator9[empty, None, None]':
    nonlocal return_1
    ...
    if v_2 > 0:
        _console_3.log('pos')
    else:
        return_1 = done_result()
```

(that listing is from the same shape with an `await` before the `if`; the
`await` makes no difference to py.)

[`in-a-function`](in-a-function/src/main.temper.md) puts the block inside a
function and fails the same way, with `return_4`, the `nonlocal` emitted in
both the function and the generator. [`controls`](controls/src/main.temper.md)
has two blocks that run on py: one whose `if` has an `else`, and one with a
statement after the `if`.

```sh
./repro.sh 28-py-async-block-ending-in-if/top-level py
./repro.sh 28-py-async-block-ending-in-if/in-a-function py
./repro.sh 28-py-async-block-ending-in-if/controls py
./repro.sh 28-py-async-block-ending-in-if/top-level js
```

## Expected

`pos` on py.

## Notes

From reading, not traced. `simplifyGeneratorFnReturns`
(`be/src/commonMain/kotlin/lang/temper/be/tmpl/TmpLControlFlow.kt:1679-1700`)
removes `return__N = core.doneResult()` only where it is an element of a
`PreTranslated.Block`. An `else` that holds just that one assignment may not
be a block, so the assignment survives and py emits it as written. That
would explain why an `if` with an explicit `else`, or a statement after the
`if`, is fine.

Found while checking the case for #542, whose
`if-after-await` library fails on py this way. The coroutine converter fix
for that case does not change this; py does not use the converter.
js was the only other backend run on these three libraries.
