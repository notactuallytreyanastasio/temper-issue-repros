# a function inside a top-level `if` reads a top-level `var`

`n` is assigned twice, so it is not a constant, and `f` is declared inside a
block at the top level of the module.

    var n = 1;
    n += 1;
    if (n > 0) {
      let f(): Void { console.log("n=${n}"); }
      f();
    }
