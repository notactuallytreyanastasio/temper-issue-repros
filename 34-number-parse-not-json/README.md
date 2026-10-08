# `toInt32`, `toInt64` and `toFloat64` accept inputs that JSON does not, and the backends disagree on which

The doc comments say `String.toInt32` and `toInt64` support "integer JSON
format, plus any radix 2 through 36", and `toFloat64` supports "numeric JSON
format plus Infinity and NaN"
(`frontend/src/commonMain/resources/core/core.temper:632-642`). JSON numbers
have no leading `+`, no leading zeros, no `_` separators and only ASCII
digits. Every backend accepts some of these. js and lua accept the same set; cpp,
rust, java and py each accept a different one:

```temper
let show(s: String): Void {
  let a = do { s.toInt32().toString() } orelse "bubble";
  let b = do { s.toInt64().toString() } orelse "bubble";
  let c = do { s.toFloat64().toString() } orelse "bubble";
  console.log("\"${s}\" Int32 ${a} | Int64 ${b} | Float64 ${c}");
}
show("+5"); show("05"); show("01.5"); show("+1.5"); show("1_0"); show("\u{663}");
```

`"\u{663}"` is ٣, ARABIC-INDIC DIGIT THREE. Each cell is Int32 / Int64 /
Float64, and `-` means it bubbled:

| input | js | lua | cpp | rust | java, interp | py |
|---|---|---|---|---|---|---|
| `+5` | 5 / - / - | 5 / - / - | 5 / 5 / - | 5 / 5 / 5.0 | 5 / 5 / 5.0 | 5 / 5 / 5.0 |
| `05` | 5 / 5 / 5.0 | 5 / 5 / 5.0 | 5 / 5 / 5.0 | 5 / 5 / 5.0 | 5 / 5 / 5.0 | 5 / 5 / 5.0 |
| `01.5` | - / - / 1.5 | - / - / 1.5 | - / - / 1.5 | - / - / 1.5 | - / - / 1.5 | - / - / 1.5 |
| `+1.5` | - / - / - | - / - / - | - / - / - | - / - / 1.5 | - / - / 1.5 | - / - / 1.5 |
| `1_0` | - / - / - | - / - / - | - / - / - | - / - / - | - / - / - | 10 / 10 / 10.0 |
| `٣` | - / - / - | - / - / - | - / - / - | - / - / - | 3 / 3 / - | 3 / 3 / 3.0 |

What stands out:

- Leading zeros (`05`, `01.5`) are accepted everywhere.
- A leading `+` depends on the backend and, on js and lua, on the method:
  `"+5".toInt32()` is 5 but `"+5".toInt64()` bubbles.
- py accepts `_` separators and any Unicode decimal digit, because it calls
  Python's `int()` and `float()`. java and the interpreter accept Unicode
  digits for integers only, through `Integer.parseInt` and `Long.parseLong`,
  and reject them for `toFloat64`.

```sh
./repro.sh 34-number-parse-not-json/parse-non-json py
./repro.sh 34-number-parse-not-json/parse-non-json js
./repro.sh 34-number-parse-not-json/parse-non-json java
```

## Expected

The JSON grammar the doc names, the same on every backend: all of the inputs
above bubble from `toInt32` and `toInt64`, and from `toFloat64`. If leading
zeros or `+` are meant to be allowed, the doc should say so, and the
backends should agree.

## Notes

From reading, at `ffba652a`:

- py: `string_to_int32` and `string_to_int64` are `int(string, radix or 10)`
  plus a range check, and `string_to_float64` is `float(string)` plus checks
  for a leading or trailing `.` and for `nan`/`inf` spellings
  (`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:738-771`).
  Python's `int` and `float` accept `+`, `_` between digits, surrounding
  whitespace and any Unicode `Nd` digit.
- java: `Integer.parseInt(s.trim(), radix)`, `Long.parseLong(s.trim(), radix)`
  and `Double.parseDouble(s)`
  (`be-java/src/commonMain/resources/lang/temper/be/java/temper-core/src/main/java/temper/core/Core.java:648-670`).
  `parseInt` accepts `+` and Unicode digits through `Character.digit`;
  `parseDouble` accepts `+` but only ASCII digits.
- js: `stringToFloat64` checks `^\s*-?(?:\d+(?:\.\d+)?(?:[eE][-+]?\d+)?|NaN|Infinity)\s*$`
  (`be-js/src/commonMain/resources/lang/temper/be/js/temper-core/string.js:52-58`),
  which allows leading zeros. `stringToInt32` uses `parseInt` (line 66),
  which accepts `+`; `stringToInt64` uses the hand-written `parseBigInt`
  (`core.js:37`), which only looks for `-`.
- lua: `toInt32` and `toInt64` are `tonumber(str, radix)` plus a range
  check (`be-lua/.../temper-core/init.lua:1448`, `intnew.lua:169`);
  `toFloat64` uses the pattern `^%s*(-?)%d+(%.?)(%d*)[eE]?[-+]?%d*%s*$`
  (`init.lua:1432`), which allows leading zeros. Why `"+5"` passes for
  `toInt32` and fails for `toInt64` on lua was not traced.
- cpp: `toFloat64` checks its own grammar before `std::stod`
  (`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/string.hpp:256`),
  and that grammar has no `+`; the integer parsers (lines 317 and 374)
  accept `+`; not traced further.

The functional test `types/float/basics` checks `"2."`, `".2"`, `"2.0.0"`,
`"-inf"` and `"totally"`, but none of the inputs here.

With a non-default radix, the doc's "integer JSON format" does not
obviously apply; this case only uses the default radix.

Not checked: csharp.
