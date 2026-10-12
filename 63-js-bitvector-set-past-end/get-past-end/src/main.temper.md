# `get` and `set` past a vector's capacity

    let v = new DenseBitVector(16);
    v.set(3, true);
    console.log("get 3: ${v.get(3).toString()}");
    console.log("get 100: ${v.get(100).toString()}");
    v.set(100, true);
    console.log("after set 100, get 100: ${v.get(100).toString()}");
