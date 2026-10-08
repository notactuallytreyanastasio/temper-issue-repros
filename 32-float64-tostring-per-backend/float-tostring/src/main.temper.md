# Float64.toString on a fixed set of values, and whether each reads back

    let show(x: Float64): Void {
      let s = x.toString();
      let back = do {
        if (s.toFloat64() == x) { "reads back" } else { "reads back as a different number" }
      } orelse "does not parse";
      console.log("${s}  ${back}");
    }
    let tenth = 0.1;
    show(100.0);
    show(1.5);
    show(tenth + 0.2);
    show(1.0 / 3.0);
    show(0.000001);
    show(1.0e-7);
    show(123456789.0);
    show(1.0e15);
    show(1.0e16);
    show(1.0e21);
    show(1.7976931348623157e308);
    show(5.0e-324);
    show(-0.0);
