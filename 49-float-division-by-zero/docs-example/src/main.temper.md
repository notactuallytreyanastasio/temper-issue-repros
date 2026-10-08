# the example from builtins.md, with constant operands

    console.log("${ (0.0 /  0.0).toString() orelse "Bubble" }");
    console.log("${ (1.0 /  0.0).toString() orelse "Bubble" }");
    console.log("${ (1.0 / -0.0).toString() orelse "Bubble" }");
