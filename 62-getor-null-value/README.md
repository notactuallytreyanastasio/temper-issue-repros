# js: `Mapped.getOr` returns the fallback for a key that is present with a null value

`getOr` is documented as "falling back to [fallback] when no such key
exists" (`frontend/src/commonMain/resources/core/core.temper:1184`), and
core.temper's own body is `return this[key] orelse fallback;`. A key
mapped to `null` exists: `has` says `true` and `this[key]` answers `null`
on every backend. The interpreter, py, rust, java and cpp then answer
`null` from `getOr`. js answers the fallback.

[`null-value`](null-value/src/main.temper.md):

```temper
let builder = new MapBuilder<String, String?>();
builder["n"] = null;
show("builder has n", builder.has("n").toString());
show("builder get n", do { builder["n"] ?? "null" } orelse "bubble");
show("builder getOr n", builder.getOr("n", "fallback") ?? "null");
show("builder getOr absent", builder.getOr("absent", "fallback") ?? "null");

let map = builder.toMap();
// the same four lines for map
```

| line | interp, py, rust, java, cpp | js |
|---|---|---|
| `builder has n` | `true` | `true` |
| `builder get n` | `null` | `null` |
| `builder getOr n` | `null` | `fallback` |
| `builder getOr absent` | `fallback` | `fallback` |
| `map has n` | `true` | `true` |
| `map get n` | `null` | `null` |
| `map getOr n` | `null` | `fallback` |
| `map getOr absent` | `fallback` | `fallback` |

So on js, `m.getOr(k, f)` and `m[k] orelse f` disagree for the same map,
and a program cannot tell "absent" from "present and null" through
`getOr`, though `has` and `get` can.

```sh
./repro.sh 62-getor-null-value/null-value js
./repro.sh 62-getor-null-value/null-value py
./repro.sh 62-getor-null-value/null-value interp
./62-getor-null-value/run-java.sh
```

java's line is from `run-java.sh`, which builds with the CLI and runs
`javac`/`java` directly, because `temper run -b java` stops on the JDK
version `21.0.12.1` ([#525](https://github.com/temperlang/temper/issues/525)).
lua did not run here (no `lua` on PATH, which the CLI reports as a
NullPointerException, [#570](https://github.com/temperlang/temper/issues/570)),
nor csharp (no `dotnet`).

## Expected

`null` from both `getOr` calls on the key `"n"` on js, as on the other
backends and as the doc comment and core.temper's body say.

## Notes

From reading, at `ffba652a`. js's runtime uses `??`, which treats `null`
like `undefined`:

```js
export const mappedGetOr = (map, key, fallback) => {
  return map.get(key) ?? fallback;
}
```

(`be-js/src/commonMain/resources/lang/temper/be/js/temper-core/mapped.js:139-141`).
`map.has(key) ? map.get(key) : fallback` would match the others. js's
`mappedGet` a few lines up (`mapped.js:122-130`) already tests
`=== undefined`, which is why `get` answers `null` correctly. The other
backends look the key up rather than test the value:

- py: `dict.get(key, fallback)` (`be-py/src/commonMain/kotlin/lang/temper/be/py/PySupportNetwork.kt:830-832`)
- java: `Map.getOrDefault` (`be-java/src/commonMain/kotlin/lang/temper/be/java/JavaSupportNetwork.kt:1320-1322`)
- rust: `self.0.get(&key).cloned().unwrap_or(fallback)` (`be-rust/src/commonMain/resources/lang/temper/be/rust/temper-core/src/mapped.rs:107-109`)
- cpp: `m->data.find(key)` (`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/mapped.hpp:37-42`)
