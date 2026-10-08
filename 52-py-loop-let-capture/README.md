# Comment on #264: py still late-binds a `let` in a loop body, and a `for (let x of xs)` variable

Still reproduces at `ffba652a`, and it also covers two shapes the thread does
not show: a `let` computed inside the loop body (not a copy of the counter),
and the variable of `for (let x of xs)`, which needs no `let x = x;` on any
other backend.

```temper
let run(xs: List<Int>, n: Int): String {
  let fs = new ListBuilder<fn (): Int>();
  for (var i = 0; i < n; i += 1) {
    let s = i * 10;
    fs.add(fn (): Int { s });
  }
  for (let x of xs) {
    fs.add(fn (): Int { x });
  }
  fs.join(",") { f => f().toString() }
}
console.log(run([7, 8, 9], 3));
```

```
js, java, lua, rust, cpp, interpreter   0,10,20,7,8,9
py                                      20,20,20,9,9,9
```

The `for of` loop becomes a `while` with the element bound by plain
assignment, so the closure sees the last element:

```python
while i_20 < n_19:
    el_21: 'int8' = _list_get_102(this_17, i_20)
    i_20 = _int_add_103(i_20, 1)
    x_7: 'int8' = el_21
    def fn_24() -> 'int8':
        return x_7
    fs_6.append(fn_24)
```

A `while` loop with `let k = j;` in its body gives the same `2,2,2` on py.

Case: [`let-in-loop`](let-in-loop/src/main.temper.md).

```sh
./repro.sh 52-py-loop-let-capture/let-in-loop py
```

Not checked: csharp.
