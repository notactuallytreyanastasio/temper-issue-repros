# a Void method that sets a field, then bubbles

    class P {
      public var errAt: Int = -1;
      public fail(n: Int): Void throws Bubble {
        errAt = n;
        bubble();
      }
    }
    let p = new P();
    var n = 7;
    n = n;
    p.fail(n) orelse void;
    console.log("${p.errAt}");
