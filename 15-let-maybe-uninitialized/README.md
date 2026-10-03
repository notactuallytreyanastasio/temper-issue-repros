# A `let` assigned a constant on only one branch builds without an error and reads as that constant

The frontend reports a read of a name that might not be initialized, but not
in this shape:

```temper
export let f(b: Boolean): Int {
  let x: Int;
  if (b) { x = 1; }
  x
}
```

`temper build` exits 0 with no diagnostic, and the read of `x` is replaced
by the constant, so `f(false)` returns `1`:

```js
export function f(b_0) {
  let x_1;
  if (b_0) {
    x_1 = 1;
  }
  return 1;
};
```

```
js build exit code: 0
js f(true) = 1  f(false) = 1
py build exit code: 0
py f(True) = 1  f(False) = 1
```

The same function with `var` in place of `let`, with `x = n` in place of
`x = 1`, or with no assignment at all is rejected, as
[`controls`](controls/src/main.temper.md) shows:

```
[-work/src/main.temper.md:5+6-7]@T: x__4 is not initialized along branches at [:4+6]
[-work/src/main.temper.md:11+6-7]@T: y__7 is not initialized along branches at [:10+23]
[-work/src/main.temper.md:17+6-7]@T: z__11 is not initialized along branches at [:16+23]
```

So the miss is a `let` whose only assignment is a constant.

```sh
./repro.sh 15-let-maybe-uninitialized/controls js
./15-let-maybe-uninitialized/run-generated.sh
```

`run-generated.sh` builds [`one-branch`](one-branch/src/main.temper.md) for
js and py and calls `f(true)` and `f(false)` in each.

## Expected

The same diagnostic as the controls, `x__N is not initialized along
branches`, and no code that reads `x` as `1` when `b` is false.

## Notes

The check that rejects the controls is `UseBeforeInit`
(`frontend/src/commonMain/kotlin/lang/temper/frontend/UseBeforeInit.kt:144`).
From the output alone: the `let` and its single constant assignment are
folded into the read, which becomes `return 1`, so by the time a read of
`x` would be checked there is none. Not traced to the pass that does the
folding.
