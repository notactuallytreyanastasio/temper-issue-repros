# A function's last expression is dropped after a loop that holds both a `return` and a `continue` or `break`

The interpreter runs this without complaint and returns the loop
counter's last value instead of `-7`:

```temper
let afterContinue(inputs: List<String>): Int {
  for (var i = 0; i < inputs.length; ++i) {
    if (inputs[i] == "") { continue; }
    return i;
  }
  -7
}
```

[`lost`](lost/src/main.temper.md) calls it on `[""]` and `["", ""]`, where
no element reaches the `return`, and calls the same loop with `break` in
place of `continue` on `[""]`:

| Backend | `afterContinue([""])` | `afterContinue(["", ""])` | `afterBreak([""])` |
|---|---|---|---|
| interp | `1` | `2` | `0` |
| js | `TypeError: Cannot read properties of undefined (reading 'toString')` | | |
| py | `UnboundLocalError: cannot access local variable 'return_0' where it is not associated with a value` | | |
| cpp | `37532992` | `37532992` | `1` |
| rust | does not compile | | |
| java (`javac`) | does not compile | | |

Each should be `-7`. The frontend drops the `-7` before any backend sees
it, so each backend translates what is left. js returns a variable
nothing assigned in one function, and in the other falls off the end:

```js
export function afterContinue(inputs_2) {
  let i_3 = 0;
  let return_4;
  while (i_3 < inputs_2.length) {
    continue_5: {
      if (listedGet(inputs_2, i_3) === "") {
        break continue_5;
      }
      return_4 = i_3;
      break;
    }
    i_3 = i_3 + 1 | 0;
  }
  return return_4;
};
export function afterBreak(inputs_6) {
  let i_7 = 0;
  while (i_7 < inputs_6.length) {
    if (listedGet(inputs_6, i_7) === "") {
      break;
    }
    return i_7;
  }
};
```

cpp reads the uninitialized variable, so its first two numbers are
whatever was in memory. rust and javac reject the output for the same
reason:

```
error[E0381]: used binding `return__0` is possibly-uninitialized
  --> src/mod.rs:29:12
18 |     let return__0: i32;
24 |             return__0 = i__6;
29 |     return return__0;
error[E0308]: mismatched types
  --> src/mod.rs:34:5
31 |   pub (crate) fn after_break(inputs__7: impl temper_core::ToList<std::sync::Arc<String>>) -> i32 {
```

```
LostGlobal.java:33: error: missing return statement
LostGlobal.java:23: error: variable return__0 might not have been initialized
        return return__0;
```

It takes both jumps. [`controls`](controls/src/main.temper.md) has a loop
with only a `return` and a loop with only a `continue`, each followed by
`-7`, and prints `-7` twice on interp, js, py, rust and cpp.

```sh
./repro.sh 60-trailing-value-after-loop/lost interp
./repro.sh 60-trailing-value-after-loop/lost js
./repro.sh 60-trailing-value-after-loop/lost py
./repro.sh 60-trailing-value-after-loop/lost cpp
./repro.sh 60-trailing-value-after-loop/lost rust
./repro.sh 60-trailing-value-after-loop/controls js
```

java cannot run under `temper run` here because of
[#525](https://github.com/temperlang/temper/issues/525); its row is
`javac` on the sources `temper build -b java` writes. lua and csharp ran
after the issue was filed; see the end.

## Expected

`-7` for all three calls on every backend.

## Notes

The cause is in
`frontend/src/commonMain/kotlin/lang/temper/frontend/typestage/UnsetTerminalExpressions.kt`,
the pass that decides which expression is a function's result. The
`return` macro leaves an assignment to the function's return variable,
and the pass skips a trailing expression when every path to it has
already made that assignment. For `ControlFlow.Loop` it walks the body
once, start to end, and carries what it learned out of the loop. A body
that ends in `return i;` has assigned the return variable by its end, so
after the loop the `-7` looks like dead code. But a loop can end without
finishing its body: the condition can fail first, and a `continue` or
`break` can skip the `return`. In the control `returnOnly` the `return` is inside an
`if`, so the walk already counts the assignment as happening only
sometimes.

This change fixes it. It is on a local branch of ours, not yet a PR.
With it, `lost` prints `-7` three times on interp, js, py, cpp and rust,
and the frontend's 721 jvm tests pass. A new unit test in
`UnsetTerminalExpressionsTest`, `assignmentInLoopBodyMayNotHappen`, fails
without it:

```diff
             is ControlFlow.Loop -> {
+                val beforeLoop = notes
                 notes = notes.bumpExclusion(1)
                 notes = walkRef(t, cf.condition, notes, false)
                 notes = walk(t, cf.body, notes, false)
                 notes = walk(t, cf.increment, notes, false)
                 notes = notes.bumpExclusion(-1)
+                // The walk above goes through the body once, start to end, but
+                // a loop can be left without finishing its body: the condition
+                // can fail first, and a `break` or `continue` can skip what
+                // follows it. So an assignment in the body, such as the one a
+                // `return` makes, may not have happened after the loop.
+                notes = mergeNotes(beforeLoop, notes)
                 if (inTerminalPosition && notes.returnsPrior != Freq3.Always) {
                     throw MissingTerminalExpression(notes)
                 }
```

[#536](https://github.com/temperlang/temper/issues/536) has the same
symptom, a `return__N` nothing assigns, with a different cause: a `Void`
body that ends in `panic()`. PR
[#572](https://github.com/temperlang/temper/pull/572) fixes that one in
`be/.../tmpl/TmpLTranslator.kt` and does not touch this pass.

## lua and csharp, after filing

lua (5.5.1) and csharp (.NET 10.0.401) are installed here now, so here they are, from the same CLI at `ffba652a`. Neither gets `-7`.

lua: `afterContinue` returns `return__0`, which nothing assigned, so it is `nil`, and the program dies converting it to a string:

```
temper-core/init.lua:1177: bad argument #2 to 'string_format' (number expected, got nil)
```

csharp does not compile, for the same reasons as rust and javac:

```
LostGlobal.cs(27,20): error CS0165: Use of unassigned local variable 'return__0'
LostGlobal.cs(29,29): error CS0161: 'LostGlobal.AfterBreak(IReadOnlyList<string>)': not all code paths return a value
```

`controls` prints `-7` twice on both.
