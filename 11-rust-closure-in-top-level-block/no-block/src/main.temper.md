# control: the same function, not inside a block

This one compiles on rust, because `f` is a module-level function and `n`
becomes a module-level `static`.

    var n = 1;
    n += 1;
    let f(): Void { console.log("n=${n}"); }
    f();
