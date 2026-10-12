# A generic function passed as a value with its type argument, `identity<Int>`, fails at run time on every backend except the interpreter

The frontend asks for the type argument and then no backend can translate
it. [`as-value`](as-value/src/main.temper.md) passes a generic function
where a function type is expected:

```temper
let identity<T>(x: T): T { x }
let apply(f: fn (Int): Int, x: Int): Int { f(x) }

console.log("before");
console.log(apply(identity<Int>, 5).toString());
```

The interpreter prints `before` and `5`. js prints nothing at all, because
the module throws while it loads:

```js
/** @type {'Unsupported type: <Garbage "Invalid"> : class lang.temper.be.tmpl.TmpL$GarbageType'} */
const fLtGt = (() => {
    throw "builtin <> not supported by JS backend";
})();
```

```
builtin <> not supported by JS backend
(Use `node --trace-uncaught ...` to show where the exception was thrown)
Run failed
```

py prints `before`, then fails when `apply` calls the placeholder it was
given:

```python
_console_10.log(_int_to_string_100(_apply(('<<notSupported(<>): Builtin(<>, null, species=Pure)>>', NotImplemented)[1], 5)))
```

```
before
    return f_7(x_8)
TypeError: 'NotImplementedType' object is not callable
Run failed
```

Every backend except py logs the same two lines while building, and then
runs the output anyway:

```
[-work/src/main.temper.md:7+30-31]: Cannot translate builtin <> not supported by JS backend
[-work/src/main.temper.md:7+30]: Cannot translate Invalid
```

| Backend | Result |
|---|---|
| interp | `before`, `5` |
| js | throws `builtin <> not supported by JS backend` while loading; prints nothing |
| py | `before`, then `TypeError: 'NotImplementedType' object is not callable`; no build diagnostic |
| rust | rustc rejects `let f<>___101: () = panic!("Unsupported: ...");` with `expected one of ... found '<'` |
| cpp | g++: `use of undeclared identifier 'fltgt_0'` |
| lua | emits `fltgt_0 = temper.bubble('builtin <> not supported by Lua Backend')`; not run, no `lua` on this machine (and the CLI then throws a NullPointerException, [#570](https://github.com/temperlang/temper/issues/570)) |
| java | emits `f$3c$3e_100 = "(GarbageExpression\n  (Diagnostic \"builtin <> not supported by Java / JVM Backend\"))";`; not run, `temper run -b java` stops on the JDK version `21.0.12.1` ([#525](https://github.com/temperlang/temper/issues/525)) |
| csharp | emits `f<>___100 = C::Core.Garbage("builtin <> not supported by C# Backend")`; not run, no `dotnet` on this machine |

The type argument is not optional. Without it,
[`plain-generic`](plain-generic/src/main.temper.md) is rejected:

```
[-work/src/main.temper.md:6+22-30]@G: Expected subtype of fn (Int32): Int32, but got fn<T__0 extends AnyValue>(T__0): T__0
```

(That build then runs anyway and prints `5` on interp, js and py before
`Run failed`, which is the failed-build-still-runs shape of
[#511](https://github.com/temperlang/temper/issues/511).) So a generic
function can be passed as a value only by naming its type argument, and
only the interpreter runs that.

The call form works everywhere tried:
[`call-control`](call-control/src/main.temper.md), `identity<Int>(5)`,
prints `5` on interp, js and py.

```sh
./repro.sh 61-generic-function-value/as-value interp
./repro.sh 61-generic-function-value/as-value js
./repro.sh 61-generic-function-value/as-value py
./repro.sh 61-generic-function-value/as-value rust
./repro.sh 61-generic-function-value/plain-generic js
./repro.sh 61-generic-function-value/call-control js
```

## Expected

`as-value` prints `before` and `5` on every backend, as it does on the
interpreter.

## Notes

From reading, at `ffba652a`. When `identity<Int>` is called, the
frontend removes the `<Int>` and the backend sees a plain call. When it is
a value, it stays a call to the builtin `<>`, `TypeAngleFn`
(`builtin/src/commonMain/kotlin/lang/temper/builtin/TypeFuns.kt:208`),
with the function and the type as arguments, and the call's type is
`Invalid`, hence `Cannot translate Invalid`. The builtin's own doc comment
says that applied to a function, "the result is just the function passed
in as the significance of the function is apparent during static typing",
and in full interpretation it returns its first argument
(`TypeFuns.kt:224-229`), which is why the interpreter works.

No backend's support network has an entry for `<>`. In the shared layer
that ends in `untranslatableTopLevel(pos, "builtin $connectedName not
supported by ${supportNetwork.backendDescription}")`
(`be/src/commonMain/kotlin/lang/temper/be/tmpl/TmpLTranslator.kt:2889`),
which logs the diagnostic and emits a garbage top level; js, rust, cpp,
lua, java and csharp each turn that into the code above. py's support
network falls back to `notSupported(builtin.name, builtin)`
(`be-py/src/commonMain/kotlin/lang/temper/be/py/PySupportNetwork.kt:70`,
defined at `:947`), an inline garbage expression, which is why py logs
nothing at build time and fails only when the value is called.

Since the runtime value is the function itself, one fix is for each
backend (or TmpL, before them) to translate `<>(f, T)` used as a value as
`f`, typed with the signature after substituting the type arguments.
The type formals come from `f`'s declaration; the reference's own
signature does not carry them.
