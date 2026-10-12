# `DenseBitVector.set` loses a bit set at index 128 or above on js, whatever the capacity, and on cpp any `set` or `get` past the capacity kills the program

The documentation for `DenseBitVector.set` says "After this, [get],
given [index], will return [newValue]"
(`frontend/src/commonMain/resources/core/core.temper:1453-1455`). On js a
bit set at index 128 or above on a new vector reads back as `false`. The
capacity passed to the constructor makes no difference: a vector made with
`new DenseBitVector(1000)` loses bit 500. Setting the same bit a second
time does work.

[`set-past-end`](set-past-end/src/main.temper.md) makes a new vector for
each line, sets one bit, and reads it back:

```temper
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
```

| line | js | py, rust, interpreter |
|---|---|---|
| capacity 0, set 63 | true | true |
| capacity 0, set 64 | true | true |
| capacity 0, set 127 | true | true |
| capacity 0, set 128 | **false** | true |
| capacity 0, set 1000 | **false** | true |
| capacity 16, set 200 | **false** | true |
| capacity 1000, set 500 | **false** | true |
| set 200 once | **false** | true |
| set 200 twice | true | true |

cpp prints nothing for this library. Its first line, `set(63)` on a vector
of capacity 0, raises a bubble that nothing catches, since `set` is not
declared to throw:

```
libc++abi: terminating due to uncaught exception of type temper::core::TemperBubble: DenseBitVector set index out of bounds
```

`get` does the same on cpp. The documentation for `get` says "If a bit has
not previously been set then it is assumed to be false" (`core.temper:1440-1443`).
[`get-past-end`](get-past-end/src/main.temper.md):

```temper
let v = new DenseBitVector(16);
v.set(3, true);
console.log("get 3: ${v.get(3).toString()}");
console.log("get 100: ${v.get(100).toString()}");
v.set(100, true);
console.log("after set 100, get 100: ${v.get(100).toString()}");
```

js, py, rust and the interpreter print `get 3: true`, `get 100: false`,
`after set 100, get 100: true`. cpp prints `get 3: true`, then:

```
libc++abi: terminating due to uncaught exception of type temper::core::TemperBubble: DenseBitVector index out of bounds
```

```sh
./repro.sh 63-js-bitvector-set-past-end/set-past-end js
./repro.sh 63-js-bitvector-set-past-end/set-past-end py
./repro.sh 63-js-bitvector-set-past-end/set-past-end cpp
./repro.sh 63-js-bitvector-set-past-end/get-past-end cpp
```

lua and csharp were not run: there is no `lua` here, and the CLI throws
the NullPointerException from
[#570](https://github.com/temperlang/temper/issues/570), and no `dotnet`.
java was not run because `temper run -b java` on `ffba652a` rejects the
JDK version `21.0.12.1`
([#525](https://github.com/temperlang/temper/issues/525)).

## Expected

Every line `true` in `set-past-end` on every backend, as py, rust and the
interpreter print. `get` past the end answers `false` on cpp, and `set`
past the end grows the vector, as `core.temper`'s own implementation does
(`core.temper:1466-1481`).

## Notes

js. `be-js/src/commonMain/resources/lang/temper/be/js/temper-core/bitvector.js`:

```js
  constructor() {
    this.values = new Uint8Array(8);
  }
  ...
  set(index, newBitValue) {
    let values = this.values;
    const len = values.byteLength;
    const key = index >> 3;
    const shift = index & 7;
    if (len <= key) {
      const next = new Uint8Array(len << 1);
      next.set(values);
      next[key] = next[key] & ~(1 << shift) | (newBitValue << shift);
      this.values = next;
    } else {
      values[key] = values[key] & ~(1 << shift) | (newBitValue << shift);
    }
  }
```

(lines 29-31 and 46-59). Every vector starts with 8 bytes, 64 bits,
because `denseBitVectorConstructor` ignores its `capacity` argument (line
81-83). When `set` needs more room it doubles the storage once, then writes
`next[key]`. If `key` is still past the end of the doubled array, the
write is dropped: a `Uint8Array` ignores writes outside its length. Node
24.19.0:

```
$ node -e 'const a = new Uint8Array(16); a[25] = 1; console.log(a[25], a.length)'
undefined 16
```

So on a new vector, indexes up to 127 fit after one doubling and 128 and
up are lost. The dropped `set` still keeps the doubled array, which is why
the second `set(200)` works: the storage is 16 bytes by then, and doubling
to 32 covers byte 25. Growing until `key` fits, as `core.temper` does with
its `while` loop, would fix it.

cpp. `be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/dense_bit_vector.hpp:12-30`
makes a `std::vector<bool>` of exactly `capacity` elements, and `get` and
`set` both call `bubble` for an index outside it. This is from reading;
the outputs above are from running it.
