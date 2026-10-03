# a recursive local function that reads a field

    export class Counter(public n: Int) {
      public sumTo(): Int {
        let go(i: Int): Int {
          if (i <= 0) { 0 } else { n + go(i - 1) }
        }
        go(3)
      }
    }
