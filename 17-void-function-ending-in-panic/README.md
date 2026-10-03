# A `Void` function or method whose body ends in `panic()` or `bubble()` fails to build on js and rust

The build stops with an error about an export that the source never names:

```temper
export class Gate {
  public fail(): Void { panic(); }
}

export let failFn(): Void { panic(); }
```

```
[-work/src/main.temper.md:4+38]: -work/src// does not export symbol return__3
[-work/src/main.temper.md:7+42]: -work/src// does not export symbol return__4
```

js and rust both report this and exit 1. py builds the same source, and the
output does what the source says:

```python
def fail(this_0, /) -> 'None':
    raise RuntimeError0()
...
def fail_fn() -> 'None':
    raise RuntimeError0()
```

The same happens with `bubble()`
([`function-ends-in-bubble`](function-ends-in-bubble/src/main.temper.md)):

```temper
export let f(): Void throws Bubble { bubble(); }
```

```
[-work/src/main.temper.md:3+52]: -work/src// does not export symbol return__0
```

Two nearby shapes build on js, py and rust
([`controls`](controls/src/main.temper.md)): `panic()` as the body of an
`Int` function, and `panic()` inside an `if` in a `Void` function.

```sh
./repro.sh 17-void-function-ending-in-panic/method-ends-in-panic js
./repro.sh 17-void-function-ending-in-panic/method-ends-in-panic rust
./repro.sh 17-void-function-ending-in-panic/function-ends-in-bubble js
./repro.sh 17-void-function-ending-in-panic/controls js
```

## Expected

A build like py's: the function raises when called.

## Notes

The message is `MessageTemplate.NotExported`
(`log/src/commonMain/kotlin/lang/temper/log/MessageTemplate.kt:322`). Of the
three places that report it, `be/src/commonMain/kotlin/lang/temper/be/FinishTmpLImports.kt:86`
is the one in the shared backend layer, which would fit js and rust failing
while py does not. That is from reading; not traced. The `return__N` name
looks like the function's result variable, which a body that never returns
leaves without an assignment. csharp, java, cpp and lua were not run.
