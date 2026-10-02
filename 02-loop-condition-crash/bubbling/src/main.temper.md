# a loop whose condition bubbles

    let countBelow(s: String): Int throws Bubble {
      var i = 0;
      while (i < s.toInt32()) { i += 1; }
      i
    }

    console.log("countBelow=${countBelow("abc") orelse -1}");
