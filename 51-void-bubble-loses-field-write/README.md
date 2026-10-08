# Comment on #536: On js the dangling return__N loses a field write

On js the dangling `return__N` also changes behavior when `temper run`
goes ahead and runs the failed build. A `Void` method that sets a field
and then bubbles loses the field write:

```temper
class P {
  public var errAt: Int = -1;
  public fail(n: Int): Void throws Bubble {
    errAt = n;
    bubble();
  }
}
let p = new P();
var n = 7;
n = n;
p.fail(n) orelse void;
console.log("${p.errAt}");
```

```
[-work/src/main.temper.md:8+7]: -work/src// does not export symbol return__4
-1
```

py, java and cpp print `7`. The js method starts with an assignment to the
undeclared result variable:

```js
fail(n_4) {
  return_5 = void 0;
  this.#errAt_2 = n_4;
  throw Error();
}
```

In an ES module that line throws `ReferenceError: return_5 is not defined`
(checked by calling `p.fail(7)` from a small script against the output),
so the method exits before the field write, and the caller's `orelse`
takes the `ReferenceError` for the bubble. `temper build -b js` exits 1, so
this needs the output of a failed build to run, which ties it to #511 as
well.

lua reports the same `does not export symbol return__4` and exits 1, but
its output, `return__4 = nil;`, assigns a global, so the lua run prints
`7`. rust fails to compile with `E0425` on `return__4`. That makes lua the
third backend with the build error; the description listed js and rust.
java and cpp build and run this program without the error. csharp was not
run. All at `ffba652a`.
