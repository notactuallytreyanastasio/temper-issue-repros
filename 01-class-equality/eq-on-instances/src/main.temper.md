# `==` between two instances of a class

    export class Point(public x: Int) {}

    export let same(a: Point, b: Point): Boolean { a == b }

    test("a point equals itself") { test =>
      let p = new Point(1);
      assert(same(p, p)) { "not equal" }
    }
