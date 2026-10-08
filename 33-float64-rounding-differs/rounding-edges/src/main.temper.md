# floor, ceil and round on edge values

    let show(s: String): Void {
      let x = s.toFloat64() orelse 0.0;
      let f = x.floor().toString();
      let c = x.ceil().toString();
      let r = x.round().toString();
      console.log("${s}: floor ${f} | ceil ${c} | round ${r}");
    }
    show("-0.0");
    show("-0.4");
    show("0.5");
    show("2.5");
    show("-2.5");
    show("0.49999999999999994");
    show("1e300");
    show("Infinity");
    show("NaN");
