# `set` then `get` on fresh vectors

Each line makes a new `DenseBitVector(capacity)`, sets one bit, and reads
it back.

    let check(capacity: Int, index: Int): Void {
      let v = new DenseBitVector(capacity);
      v.set(index, true);
      console.log("capacity ${capacity.toString()}, set ${index.toString()}: get is ${v.get(index).toString()}");
    }
    check(0, 63);
    check(0, 64);
    check(0, 127);
    check(0, 128);
    check(0, 1000);
    check(16, 200);
    check(1000, 500);

    // The same bit set twice on one vector.
    let twice = new DenseBitVector(0);
    twice.set(200, true);
    console.log("set 200 once: get is ${twice.get(200).toString()}");
    twice.set(200, true);
    console.log("set 200 twice: get is ${twice.get(200).toString()}");
