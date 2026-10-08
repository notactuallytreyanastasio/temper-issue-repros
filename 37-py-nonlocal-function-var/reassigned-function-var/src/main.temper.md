# A function-local `var` that holds a function, then is reassigned

    let main(): Void {
      var f = fn (x: Int): Int { x };
      f = fn (x: Int): Int { x + 1 };
      console.log("${f(1)}");
    }
    main();
