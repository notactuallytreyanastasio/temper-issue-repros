# String.toFloat64 on subnormal and out-of-range inputs

    let show(s: String): Void {
      let got = do { s.toFloat64().toString() } orelse "bubble";
      console.log("${s} => ${got}");
    }
    show("2.2250738585072014e-308");
    show("2.225e-308");
    show("1e-310");
    show("5e-324");
    show("1e-400");
    show("1e400");
