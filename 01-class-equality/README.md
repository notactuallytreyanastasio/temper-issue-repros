# `==` and `when` on class instances report an `Int32` signature, then fail at run time with an internal message

Since [#494](https://github.com/temperlang/temper/pull/494), the frontend
rejects `==` between two instances of a user class, and `when` over them;
`core.temper` says user types cannot extend `Equatable` yet. Two things go
wrong around that rejection.

The diagnostic describes a different operation. It reports the `Int32`
overload of `==` instead of saying that `Space` has no `==`:

```
[-work/src/main.temper.md:9+12 - 10+15]@G: Actual arguments do not match signature: (Int32, Int32) -> Boolean expected [Int32, Int32], but got [Space, Space]
```

The build then goes on and emits code, and the test fails at run time with
the compiler's internal message on js, and a `TypeError` on py, in place of
the diagnostic:

```
Test failed (js): when picks the matching instance - the string "Operator member infix nym`==` should have been converted to dot-name form" was thrown, throw an Error :)
```

```
Test failed (py): when picks the matching instance - Traceback (most recent call last):
    if ('<<TmpL: Operator member infix nym`==` should have been converted to dot-name form>>', NotImplemented)[1]:
TypeError: NotImplemented should not be used in a boolean context
```

## Source

[`when-on-class/src/main.temper.md`](when-on-class/src/main.temper.md):

```temper
export class Space(public name: String) {
  public static a = new Space("a");
  public static b = new Space("b");
}

export let describe(s: Space): String {
  when (s) {
    Space.a -> "first";
    Space.b -> "second";
    else -> "other";
  }
}
```

called from a test as `describe(Space.b)`.
[`eq-on-instances`](eq-on-instances/src/main.temper.md) is the same with a
plain `a == b` on two `Point`s, and gives the same diagnostic and the same
run-time failures.

```sh
./repro.sh 01-class-equality/when-on-class js
./repro.sh 01-class-equality/when-on-class py
./repro.sh 01-class-equality/eq-on-instances js
```

## Expected

A diagnostic that names the problem, along the lines of "`Space` does not
support `==`", and, if the build still emits code, a run-time failure that
carries that diagnostic rather than the translator's own message.

## Notes

- Both run-time messages come from
  `be/src/commonMain/kotlin/lang/temper/be/tmpl/TranslateDotHelper.kt`
  (lines 170 and 457), which turns an `OperatorMember` that reaches
  translation into garbage carrying that text.
- The change is #494's. Built from its merge's first parent, `470fbad2`,
  Temper runs the `when` case and the test passes; built from the merge,
  `f057328e`, it gives the diagnostic above.
- A color library that switches on static `Space` instances passes 12 of
  12 tests on js at `0a0f24a8` and 7 of 12 at `e9ff0d25`.
