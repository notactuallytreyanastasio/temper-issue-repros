# for-of with an if in the body, called with a constant list

    let count(xs: List<String>): Int {
      var n = 0;
      for (let w of xs) {
        if (!w.isEmpty) { n += 1; }
      }
      n
    }
    console.log("${count(["a", "", "b"])}");
