# a loop whose condition is a `!=`

    let countTo(limit: Int): Int {
      var n = 0;
      while (n != limit) { n += 1; }
      n
    }

    console.log("countTo=${countTo(2)}");
