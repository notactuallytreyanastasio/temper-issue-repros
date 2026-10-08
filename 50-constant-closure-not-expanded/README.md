# Comment on #510: Two more shapes that #513 fixes

Two more shapes that fail the same way at `ffba652a`, both fixed by #513.

A plain `fn` literal returned from a function, closing over a parameter,
with no block lambda and no `for`:

```temper
let mk(start: Int): fn (): Int {
  fn (): Int { start + 1 }
}
let c = mk(3);
console.log("${c()}");
```

```
[-work/src/main.temper.md:4+6]@D: Never reached by macro expander (S)
Not generating code for -work/src//
```

With `var k = 3; k = k;` and `mk(k)` in place of `mk(3)` it builds and
prints `4`, so it is the constant argument that matters, as in the
description.

A `for … of` whose body has an `if` fails at `@T` rather than `@D`:

```temper
let count(xs: List<String>): Int {
  var n = 0;
  for (let w of xs) {
    if (!w.isEmpty) { n += 1; }
  }
  n
}
console.log("${count(["a", "", "b"])}");
```

```
[-work/src/main.temper.md:5+24]@T: Never reached by macro expander (S)
```

Built from `ffba652a` with #513's diff applied, the first prints `4` and
the second `2`, on js and py.
