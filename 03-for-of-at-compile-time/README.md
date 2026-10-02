# `for (let x of xs)` fails the build when the compiler evaluates the function it is in

A function with a `for … of` loop builds as long as nothing calls it with
constant arguments. Once something does, at top level or in a `test`, the
frontend evaluates the call while compiling, and the build fails at the
loop body, with js and py alike:

```
5: for (let x of xs) { t += x; }
                     ⇧
[-work/src/main.temper.md:5+24]@D: Never reached by macro expander (S)
Not generating code for -work/src//
```

## Source

[`for-of/src/main.temper.md`](for-of/src/main.temper.md):

```temper
export let total(xs: List<Int>): Int {
  var t = 0;
  for (let x of xs) { t += x; }
  t
}

console.log("total=${total([1, 2, 3])}");
```

```sh
./repro.sh 03-for-of-at-compile-time/for-of js
```

## Expected

`total=6`.

## What changes the outcome

| Case | Result |
|---|---|
| [`for-of`](for-of/src/main.temper.md): the loop above, called at top level | `Never reached by macro expander (S)` at the loop body |
| [`forEach`](forEach/src/main.temper.md): `xs.forEach { (x): Void => t += x; }` in its place | the same error, at the block lambda |
| [`not-called`](not-called/src/main.temper.md): the same function with no call | builds |
| [`through-a-helper`](through-a-helper/src/main.temper.md): called from a test through a helper that takes the `Test` | builds, and the test passes |
| [`own-each`](own-each/src/main.temper.md): a user-written `each(xs) { (x: Int): Void => t += x; }`, called at top level | prints `total=6` |

A loop with no early exit is enough to trigger it. Adding a `return` or a
`break` to the body gives the same error, at stage `@T` in place of `@D`.

A user-defined higher-order function whose block lambda assigns an outer
variable evaluates without error, and so does an indexed
`for (var i = 0; i < xs.length; ++i)` loop. That points at the builtin
`forEach` that `for … of` uses.

A Temper built from `0a0f24a8` fails the same way.

In tests, the `through-a-helper` shape avoids the error.
