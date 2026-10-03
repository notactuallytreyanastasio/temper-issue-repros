# one comparison that reads two fields

    export class Gauge {
      public var inside: Int = 0;
      public var maxInside: Int = 0;
      public bump(): Void {
        inside += 1;
        if (inside > maxInside) { maxInside = inside; }
        inside -= 1;
      }
    }
