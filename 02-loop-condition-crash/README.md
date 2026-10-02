# A loop whose condition fails during compile-time evaluation crashes the compiler

When the frontend evaluates a call with constant arguments, and a `while`
loop's condition fails during that evaluation, the build stops with an
exception from the interpreter, with js and py alike:

```
Exception in thread "main" java.lang.IndexOutOfBoundsException: Index -1 out of bounds for length 0
	at java.base/java.util.ArrayList.remove(ArrayList.java:551)
	at lang.temper.common.SequenceCollectionsCompatKt.compatRemoveLast(SequenceCollectionsCompat.kt:30)
	at lang.temper.interp.Interpreter.interpretBlock(Interpreter.kt:877)
	at lang.temper.interp.Interpreter.interpretBlock$default(Interpreter.kt:432)
	at lang.temper.interp.Interpreter.interpretTreeNotSpammy(Interpreter.kt:378)
```

The condition does not have to bubble. Three shapes crash `e9ff0d25`:

```temper
// bubbling/: the condition bubbles, since "abc".toInt32() fails
let countBelow(s: String): Int throws Bubble {
  var i = 0;
  while (i < s.toInt32()) { i += 1; }
  i
}
console.log("countBelow=${countBelow("abc") orelse -1}");
```

```temper
// not-equal/: a condition that cannot bubble
let countTo(limit: Int): Int {
  var n = 0;
  while (n != limit) { n += 1; }
  n
}
console.log("countTo=${countTo(2)}");
```

```temper
// guarded-index/: s[b] is only read where it exists
let isSpace(cp: Int): Boolean { cp == 32 || (cp >= 9 && cp <= 13) }
let leadingSpaces(s: String): Int {
  var b = String.begin;
  var n = 0;
  while (s.hasIndex(b) && isSpace(s[b])) { n += 1; b = s.next(b); }
  n
}
console.log("leadingSpaces=${leadingSpaces("  ab")}");
```

```sh
./repro.sh 02-loop-condition-crash/bubbling js
./repro.sh 02-loop-condition-crash/not-equal py
./repro.sh 02-loop-condition-crash/guarded-index js
```

## Expected

`countBelow=-1`, `countTo=2` and `leadingSpaces=2`, which is what the three
print with the fix below.

## Cause

The loop handler in `Interpreter.kt` reaches its "condition was false"
branch after the condition failed. By then `handleFail` has unwound the
evaluation stack, and the handler pops the loop a second time, from an
empty stack. The `if` handler pops before it evaluates its condition and
does not have the bug.

The `bubbling` case also crashes `0a0f24a8`. The other two run fine there,
printing `countTo=2` and `leadingSpaces=2`: on `e9ff0d25` the frontend
fails those conditions at stage `@T`, with `fail(Interpreting)` and no
message, before it later folds them, and the same second pop follows. A
library with a guarded-index loop like the third case, which built on
`0a0f24a8`, no longer builds on `e9ff0d25`.

## Fix

[notactuallytreyanastasio/temper@b77cfcdf](https://github.com/notactuallytreyanastasio/temper/commit/b77cfcdf06715984a4584e521710260deb9e13a7)
makes the loop pop itself only when its condition evaluated to false, and
adds the `bubbling` shape to the `control-flow/bubble` functional test.
All three cases print the expected values with it. The change to
`Interpreter.kt` is a few lines; the commit is also part of #507.
