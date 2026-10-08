# py: a local `var` that holds a function and is reassigned gets `nonlocal` in its own function, and the module fails to import

On py the module does not load. Python rejects the generated file at compile
time:

```temper
let main(): Void {
  var f = fn (x: Int): Int { x };
  f = fn (x: Int): Int { x + 1 };
  console.log("${f(1)}");
}
main();
```

```
  File ".../reassigned_function_var/reassigned_function_var.py", line 8
    nonlocal f_5
    ^^^^^^^^^^^^
SyntaxError: no binding for nonlocal 'f_5' found
```

js prints `2`, and so does the interpreter. The generated Python declares
`f_5` `nonlocal` in the function that owns it:

```python
def _main() -> 'None':
    nonlocal f_5
    def f_5(x_6: 'int4', /) -> 'int4':
        return x_6
    def fn_100(x_8: 'int4', /) -> 'int4':
        return _int_add_101(x_8, 1)
    f_5 = fn_100
    _console_10.log(_str_cat_102(_int_to_string_103(f_5(1))))
```

The same happens inside an `async` block, because the block is a Python
function too
([`function-var-in-async-block`](function-var-in-async-block/src/main.temper.md)):

```temper
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  var f = fn (x: Int): Int { x };
  f = fn (x: Int): Int { x + 1 };
  console.log("${f(1)}");
}
```

```
SyntaxError: no binding for nonlocal 'f_3' found
```

When that block sits inside a function, both the block and the enclosing
function get `nonlocal f_6`, although `f_6` only exists in the block.

The same `var` at module level works on py (`_f = _fn_100`), as does a
reassigned `var` holding an `Int`.

```sh
./repro.sh 37-py-nonlocal-function-var/reassigned-function-var py
./repro.sh 37-py-nonlocal-function-var/function-var-in-async-block py
```

## Expected

`2` on py, with no `nonlocal` for a name the function declares itself.

## Notes

From reading `be-py/src/commonMain/kotlin/lang/temper/be/py/PyTranslator.kt`
at `ffba652a`: `findNonLocalUsages` (line 1236) collects a function's locals
from `TmpL.Formal` and `TmpL.LocalDeclaration` (line 1246) and emits
`nonlocal` for every assigned name not among them (line 1259). The
initializer `var f = fn ...` reaches TmpL as a `TmpL.LocalFunctionDeclaration`
(the `def f_5` above), which falls to `else -> true`: its name is not added
to `locals`, and the walk descends into its body. The later `f = ...` is a
`TmpL.Assignment` to a name the walk never saw declared, so it is treated as
nonlocal. The descent into nested function bodies also explains why the
enclosing function of an async block gets the `nonlocal` too. Not
confirmed by changing the code.

This turned up in a larger program that builds a pipeline with
`var pipeline = fn (x: Int): Int { x };` and reassigns it in a loop.

Not checked: java, lua, rust, cpp, csharp (the cause is in the py
translator).
