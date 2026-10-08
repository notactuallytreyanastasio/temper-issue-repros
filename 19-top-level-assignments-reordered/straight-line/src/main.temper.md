# a top-level var, read between two assignments

    var w = 0;
    console.log("before ${w}");
    w += 1;
    console.log("mid ${w}");
    w = 99;
    console.log("after ${w}");
