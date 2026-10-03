# control: a class named `Vec`, with lists, strings and a function that can fail

    class Vec(public n: Int) {}
    let half(x: Int): Int throws Bubble {
      if (x % 2 != 0) { bubble(); }
      return x / 2;
    }
    let parts = "a,b".split(",");
    console.log("n=${new Vec(parts.length).n} half=${half(4) orelse -1}");
