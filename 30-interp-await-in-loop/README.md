# Interpreter: an `await` inside a loop body always takes the `orelse` branch

In the interpreter, every `await` inside a `for` or `while` body fails, even
on a promise that has already completed. The same `await` just after the
loop succeeds.

```temper
let once = new PromiseBuilder<String>();
once.complete("same");
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  for (var i = 0; i < 2; i += 1) {
    let s = await once.promise orelse "?";
    console.log("${s} ${i}");
  }
  let t = await once.promise orelse "?";
  console.log("${t} after the loop");
}
```

Interpreter (REPL):

```
$ cd 30-interp-await-in-loop/await-in-loop && echo 'import("await-in-loop");' | "$TEMPER" repl -w .
[core/core.temper+29138-29156]@R: Print: ? 0
[core/core.temper+29138-29156]@R: Print: ? 1
[core/core.temper+29138-29156]@R: Print: same after the loop
interactive#0: void
```

js and py:

```
same 0
same 1
same after the loop
```

Whether the promise is already complete does not matter.
[`await-pending-in-loop`](await-pending-in-loop/src/main.temper.md)
completes it from top-level code after the block starts; the interpreter
prints `? 0` and `? 1`, js and py print `same 0` and `same 1`.

```sh
./repro.sh 30-interp-await-in-loop/await-in-loop js
(cd 30-interp-await-in-loop/await-in-loop && echo 'import("await-in-loop");' | "$TEMPER" repl -w .)
(cd 30-interp-await-in-loop/await-pending-in-loop && echo 'import("await-pending-in-loop");' | "$TEMPER" repl -w .)
```

Also seen, smaller programs not kept here: a `while` loop fails the same way;
an `await` inside an `if` at the same depth succeeds; an `await` in a loop
inside `do { ... } orelse` runs the `orelse`; assigning to a `var` declared
before the loop does not help.

## Expected

`same 0`, `same 1`, `same after the loop`, as js and py print.

## Notes

From reading, not traced in a debugger. The lowered code has the
assignment target declared inside the loop body, even when the source
assigns to a `var` outside the loop, because the frontend introduces a
temporary there (from `describe(0, "frontend.generateCodeStage.after")` in
the REPL):

```
while (i__2 <=> 1 < 0) {
  var t#8 ⦂ String;
  orelse#5: {
    t#8 = await do_get_promise(`-repl//i0000/`.once)
  } orelse {
    t#8 = "?"
  };
  s__1 = t#8;
  ...
```

In `interp/src/commonMain/kotlin/lang/temper/interp/Interpreter.kt` at
ffba652a, a loop pushes a fresh `BlockEnvironment` for its body (`:858`),
and ordinary statements run in the innermost environment,
`evaluation.envStack.last()` (`interpretChild`, `:586`). The `await` path
evaluates its arguments in, and assigns its result to, `mutableEnv`
(`:806`, `:841`), which is `evaluation.envStack.first()` (`:499`). The
variable is declared in the loop's environment, not the first one, so the
assignment would fail, and `handleFail` (`:640-652`) moves to the `orelse`.
That fits every variant above; I did not patch it to confirm.

Separately: with `orelse panic()` in place of `orelse "?"`, the REPL process
itself ends with `Exception in thread "main" lang.temper.value.Panic`.
