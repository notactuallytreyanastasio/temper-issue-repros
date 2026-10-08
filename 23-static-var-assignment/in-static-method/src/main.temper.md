# assigning a static var from a static method

    class C {
      public static var n: Int = 0;
      public static bump(): Void { C.n = C.n + 1; }
    }
    C.bump();
    console.log("${C.n}");
