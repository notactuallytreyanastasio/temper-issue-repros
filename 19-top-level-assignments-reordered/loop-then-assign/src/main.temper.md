# a top-level loop, then an assignment to its counter

    var w = 0;
    var n = 0;
    while (w < 3) {
      n += 1;
      w += 1;
    }
    w = 99;
    console.log("${n}");
