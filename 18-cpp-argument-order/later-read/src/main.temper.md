# a field read after a call that changes it

    class Counter {
      public var n: Int = 0;
      public bump(): Int { n += 1; n }
    }

    let show(a: Int, b: Int): String { "${ a } ${ b }" }

    let c = new Counter();
    console.log("bump=${ c.bump() } n=${ c.n }");
    console.log("args ${ show(c.bump(), c.n) }");
    console.log("plus ${ c.bump() * 10 + c.n }");
