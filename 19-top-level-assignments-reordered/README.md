# Top-level assignments to a `var` run before the statements written above them

At module top level, every assignment to a `var` is moved ahead of every
statement that reads it, wherever the assignment was written. The
assignments also reorder among themselves:

```temper
var w = 0;
console.log("before ${w}");
w += 1;
console.log("mid ${w}");
w = 99;
console.log("after ${w}");
```

```
before 100
mid 100
after 100
```

That is the output on js, py, lua, java, rust and cpp. `w = 99` runs
first and `w += 1` after it, though the source has them the other way
round. The py output shows the order the frontend chose:

```python
_w: 'int4' = 0
_w = 99
_w = _int_add_100(_w, 1)
_console_1.log(_str_cat_101('before ', _int_to_string_102(_w)))
_console_1.log(_str_cat_101('mid ', _int_to_string_102(_w)))
_console_1.log(_str_cat_101('after ', _int_to_string_102(_w)))
```

A loop is affected the same way. Here the assignment after the loop moves
above it, so the loop condition is false on entry
([`loop-then-assign`](loop-then-assign/src/main.temper.md)):

```temper
var w = 0;
var n = 0;
while (w < 3) {
  n += 1;
  w += 1;
}
w = 99;
console.log("${n}");
```

prints `0` on js, py, lua, java, rust and cpp. The js output:

```js
export let w = 0;
export let n = 0;
w = 99;
while (w < 3) {
  n = n + 1 | 0;
  w = w + 1 | 0;
}
console.log(String(n.toString()));
```

The same statements in a function body
([`inside-a-function`](inside-a-function/src/main.temper.md)) print
`before 0`, `mid 1`, `after 99` on js and py. So does the REPL, fed the
first program on one line.

```sh
./repro.sh 19-top-level-assignments-reordered/straight-line js
./repro.sh 19-top-level-assignments-reordered/loop-then-assign py
./repro.sh 19-top-level-assignments-reordered/inside-a-function js
```

## Expected

`before 0`, `mid 1`, `after 99`, and `3` for the loop: statements that
assign an already declared `var` keep their place relative to the
statements that read it.

## Notes

Top-level declarations are meant to be order-independent. The float
functional test relies on it
(`functional-test-suite/src/commonMain/resources/types/float/ops/ops.temper.md:149`,
"since top-level is order-independent, we can assign half before two").
That suits `let half = one / two;` written above `let two = ...`. It does
not fit a reassignment of a `var` that has already been initialized.

The reordering is `sortTopLevels` in
`frontend/src/commonMain/kotlin/lang/temper/frontend/syntax/SortTopLevels.kt`,
called from `SyntaxMacroStage.kt:97`. `trackTops` records every top-level
statement that assigns a top-level name as one of that name's `assigns`,
and `buildEdgeNeeds` (lines 57 to 90) makes every statement that reads the
name depend on all of them, in any position. `console.log("before ${w}")`
reads `w`, so it is ordered after `w += 1` and `w = 99`; `w += 1` reads `w`
too, so it is ordered after `w = 99`. That is from reading, and it matches
the py output above.

csharp was not run. I did not check whether a fix would change programs
in the functional test suite that read a top-level `var` above a later
assignment to it.
