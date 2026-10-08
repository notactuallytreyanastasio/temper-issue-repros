# A function type parameter bounded by an interface over itself

    interface Ord<T> {
      public less(other: T): Boolean;
    }
    class N(public v: Int) extends Ord<N> {
      public less(other: N): Boolean { v < other.v }
    }
    let smaller<T extends Ord<T>>(a: T, b: T): T { if (a.less(b)) { a } else { b } }
    console.log(smaller(new N(3), new N(2)).v.toString());
