# a method reads a field, calls out, and the callee writes back

    class Pong {
      public pong(a: Ping): Void { a.n += 1; }
    }

    class Ping(public peer: Pong) {
      public var n: Int = 0;
      public ping(): Int { peer.pong(this); n }
    }

    let p = new Ping(new Pong());
    console.log("before ping");
    console.log("ping returned ${p.ping()}");
