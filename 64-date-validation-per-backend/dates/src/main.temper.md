# Date construction and parsing

    let {Date} = import("std/temporal");

    let make(y: Int, m: Int, d: Int): Void {
      let shown = do {
        let date = new Date(y, m, d);
        "${date.toString()} weekday ${date.dayOfWeek.toString()}"
      } orelse "bubble";
      console.log("new Date(${y.toString()}, ${m.toString()}, ${d.toString()}): ${shown}");
    }
    make(1600, 2, 29);
    make(2023, 4, 30);
    make(1900, 2, 29);
    make(2023, 4, 31);
    make(2023, 0, 1);
    make(2023, 6, -1);
    make(12345, 1, 2);

    let parse(s: String): Void {
      let shown = do { Date.fromIsoString(s).toString() } orelse "bubble";
      console.log("fromIsoString \"${s}\": ${shown}");
    }
    parse("1596-03-31");
    parse("0012-11-10");
    parse("96-03-31");
    parse("1596-3-31");
    parse("1596-03-3");
    parse("1596-02-30");
    parse("1596-03-31 ");
    parse(" 1596-03-31");
    parse("+1596-03-31");
    parse("15960331");
    parse("12345-01-02");
    parse("\u{661}\u{665}\u{669}\u{666}-03-31");
