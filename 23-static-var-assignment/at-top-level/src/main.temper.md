# assigning a static var from top level

    class C {
      public static var n: Int = 0;
    }
    C.n = C.n + 1;
    console.log("${C.n}");
