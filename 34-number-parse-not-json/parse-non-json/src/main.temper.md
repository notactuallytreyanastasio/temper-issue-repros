# toInt32, toInt64 and toFloat64 on inputs that JSON does not allow

    let show(s: String): Void {
      let a = do { s.toInt32().toString() } orelse "bubble";
      let b = do { s.toInt64().toString() } orelse "bubble";
      let c = do { s.toFloat64().toString() } orelse "bubble";
      console.log("\"${s}\" Int32 ${a} | Int64 ${b} | Float64 ${c}");
    }
    show("+5");
    show("05");
    show("01.5");
    show("+1.5");
    show("1_0");
    show("\u{663}");
