# An interface whose type parameter is bounded by the interface itself

    interface Ord<T extends Ord<T>> {
      public less(other: T): Boolean;
    }
    class N(public v: Int) extends Ord<N> {
      public less(other: N): Boolean { v < other.v }
    }
    console.log(new N(3).less(new N(2)).toString());
