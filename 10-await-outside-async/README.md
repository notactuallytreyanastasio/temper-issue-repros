# `await` outside an async block passes the frontend, then each backend fails in its own way

A function or method that uses `await` but does not extend `GeneratorFn`
compiles with no diagnostic. The frontend hands the `await` to the backends
as a `TmpL.AwaitExpression` in an ordinary function, and none of them can
translate that. js and py write `await` into a non-async function and fail
to load; rust, csharp and cpp fail in their translators or in the C++
compiler; java writes a blocking `Future.get()` that javac rejects. Not one
of the failures names the Temper line or says what is wrong with it.

## Source

[`not-async/src/main.temper.md`](not-async/src/main.temper.md):

```temper
export let waitFn(p: Promise<Int>): Int {
  await p orelse -1
}

export class Box {
  public var v: Int = 0;
  public waitFor(p: Promise<Int>): Void {
    v = await p orelse -1;
  }
}

let b = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let box = new Box();
  box.waitFor(b.promise);
  console.log("method ${box.v.toString()}");
  console.log("function ${waitFn(b.promise).toString()}");
}
b.complete(3);
```

[`top-level/src/main.temper.md`](top-level/src/main.temper.md) has the
`await` at module level instead:

```temper
let b = new PromiseBuilder<Int>();
b.complete(3);
let x = await b.promise orelse -1;
console.log(x.toString());
```

```sh
./repro.sh 10-await-outside-async/not-async js
./repro.sh 10-await-outside-async/not-async py
./repro.sh 10-await-outside-async/not-async rust
./repro.sh 10-await-outside-async/not-async cpp
$TEMPER build -b csharp -w 10-await-outside-async/not-async
$TEMPER build -b lua -w 10-await-outside-async/not-async
./10-await-outside-async/run-java.sh not-async
```

and the same with `top-level`. `run-java.sh` builds with the CLI and
compiles with `javac`, because `temper run -b java` on `e9ff0d25` stops on
the JDK version string `21.0.12.1`. csharp and lua are build only: this
machine has no `dotnet` and no `lua`.

## Results

The frontend printed nothing for either library on any backend: no
diagnostic line appears before the backend's own failure. Absolute paths
below are shortened to `.../`.

| Backend | `not-async` (function and method) | `top-level` |
|---|---|---|
| js | build exits 0; run fails, `SyntaxError: Unexpected reserved word` | runs, prints `3` |
| py | build exits 0; run fails, `SyntaxError: 'await' outside async function` | run fails, `SyntaxError: 'await' outside function` |
| rust | translator crashes, `kotlin.NotImplementedError` | translator crashes, `kotlin.NotImplementedError` |
| cpp | build exits 0; g++ fails on `std::abort()` written in place of the `await` | same, g++ fails |
| csharp | translator crashes, `IllegalStateException: await not caught by statement path` | build exits 0; writes `yield return` into a static constructor (not compiled here) |
| lua | build exits 0; writes `p__6:await()` (not run here) | build exits 0; same shape (not run here) |
| java | build exits 0; javac fails, `unreported exception InterruptedException` | same, javac fails |
| interpreter (`temper repl`) | the call evaluates to `fail`, with no message | evaluates to `3` |

js, `temper.out/js/not-async/not_async.internal.js`:

```js
export function waitFn(p_11) {
  try {
    return await p_11;
  } catch {
    return -1;
  }
};
```

```
file:///.../10-await-outside-async/not-async/temper.out/js/not-async/not_async.internal.js:13
      t_6 = await p_5;
            ^^^^^

SyntaxError: Unexpected reserved word
```

py:

```
  File ".../10-await-outside-async/not-async/temper.out/py/not-async/not_async/not_async.py", line 17
    t_28 = await p_10
           ^^^^^^^^^^
SyntaxError: 'await' outside async function
```

```
  File ".../10-await-outside-async/top-level/temper.out/py/top-level/top_level/top_level.py", line 12
    _x = await _b
         ^^^^^^^^
SyntaxError: 'await' outside function
```

rust, both libraries:

```
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented.
	at lang.temper.be.rust.RustTranslator.translateExpression$be_rust(RustTranslator.kt:2115)
	at lang.temper.be.rust.RustTranslator.translateExpression$be_rust$default(RustTranslator.kt:2113)
```

cpp:

```
init.cpp:10:81: error: assigning to 'int32_t' (aka 'int') from incompatible type 'void'
   10 |         t_1 = /* unsupported: class lang.temper.be.tmpl.TmpL$AwaitExpression */ std::abort();
      |                                                                                 ^~~~~~~~~~~~
init.cpp:31:82: error: cannot initialize return object of type 'int32_t' (aka 'int') with an rvalue of type 'void'
   31 |         return /* unsupported: class lang.temper.be.tmpl.TmpL$AwaitExpression */ std::abort();
      |                                                                                  ^~~~~~~~~~~~
2 errors generated.
```

csharp, `not-async`:

```
Exception in thread "main" java.lang.IllegalStateException: await not caught by statement path: `return await (p__6);` is a class lang.temper.be.tmpl.TmpL$ReturnStatement
```

The function is what crashes it. With only the `Box` class in a scratch
library, the csharp build exits 0 and writes an iterator statement into a
`void` method:

```csharp
public void WaitFor(T::Task<int> p__6)
{
    int t___18;
    try
    {
        yield return C::Async.AwakeUpon(p__6);
        t___18 = p__6.Result;
    }
```

`top-level` puts the same `yield return` in `static TopLevelGlobal()`. By
the C# rules a `void` method or a constructor cannot be an iterator, so
neither should compile; that is from reading, not from running `dotnet`.

java, `not-async` (javac reports one error; with
`-XDshould-stop.at=GENERATE` it also reports the same error at `Box.java:8`):

```
.../not-async/temper.out/java/not-async/src/main/java/not_async/NotAsyncGlobal.java:22: error: unreported exception InterruptedException; must be caught or declared to be thrown
            return p__6.get();
                           ^
1 error
```

The interpreter, with the function typed into `temper repl`:

```sh
printf '%s\n' \
 'let waitFn(p: Promise<Int>): Int { console.log("before await"); let r = await p orelse -1; console.log("after await"); r }' \
 'let b = new PromiseBuilder<Int>(); b.complete(3);' \
 'waitFn(b.promise)' \
 'await b.promise orelse -1' | $TEMPER repl
```

```
$ interactive#0: void
$ interactive#1: void
$ before await
interactive#2: fail
$ interactive#3: 3
```

The promise is already resolved, yet the call fails and `orelse -1` does
not catch it. That matches the runtime check in `Interpreter.kt` listed
below, though its message is not printed here.

In a scratch library, the same `await` inside an `async` block
(`let x = await b.promise orelse -1` in the block body) runs and prints
`got 3` on js, py and rust, and the java build of it compiles with javac
and prints `got 3`, so the
failures above come from where the `await` is, not from `await` itself.

## Expected

A frontend error at the `await`, along the lines of the message the
interpreter already has (`await outside generator function body`), for a
function, method or module top level that does not extend `GeneratorFn`.
With that, no backend sees an `AwaitExpression` outside a generator body.

## Notes

From reading the source at `e9ff0d25`:

- `FnParts.mayYield` (`fundamentals/.../value/FnParts.kt:55`) is true only
  when the function's super types include `GeneratorFn`. Nothing in the
  frontend compares it with the body. The only frontend code that looks
  at `AwaitFn` is the Weaver (`frontend/.../Weaver.kt:550`), which moves
  the call rootward and does not check where it is.
- `TmpLTranslator` reads `fnParts.mayYield ?: false` (`be/.../tmpl/TmpLTranslator.kt:2309`)
  and translates every `await` call to `TmpL.AwaitExpression` with no check
  of the enclosing function (`TmpLTranslator.kt:1833`).
- The check exists at run time only. `Interpreter.kt:752` fails a yielding
  call whose body owner is not a `TransientUserFunction`, with
  `MessageTemplate.YieldingOutsideGeneratorFn` (`log/.../MessageTemplate.kt:235`,
  `CompilationPhase.Interpreter`). `AwaitFn.invoke` has the same fallback
  (`builtin/.../YieldingFn.kt:188`). Compiled code never reaches either.
- `GenerateCodeStage.doAfterInterpretation` already runs checks over the
  typed tree (`TypeChecker`, `UnicodeScalarChecker`, `ImuChecker` at
  `frontend/.../generate/GenerateCodeStage.kt:124-130`). A check there that
  walks each function body, not entering nested functions, and reports
  `await` or `yield` where `mayYield` is false would cover all backends.
  Coroutine bodies are still intact at that point, since the state-machine
  conversion runs later in `TmpLTranslator`. This is a suggestion; it is
  not implemented or tested here.
- The backends show that `AwaitExpression` outside a generator was never
  meant to reach them: `JsTranslator.kt:532` says "We shouldn't reach here
  in normal use" before falling back to a bare `await`;
  `RustTranslator.kt:2115` is `TODO()`; `CSharpTranslator.kt:1114` is
  `error(...)`; `CppTranslator.kt:971` writes `std::abort()`;
  `JavaTranslator.kt:1886` writes `Future.get()`.
- js accepts the top-level case because ES modules allow top-level
  `await`. That is the fallback at `JsTranslator.kt:532` working by
  accident, not support for top-level `await`.
- `yield` outside a generator function goes through the same paths by
  reading the code, but was not run here.
- Related: [#144](https://github.com/temperlang/temper/issues/144) "Adapt
  `await` to backends" tracks `await` support per backend; it does not
  cover `await` outside a generator body.
