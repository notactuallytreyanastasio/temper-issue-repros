# `Float64.toString` gives a different string for the same number on each backend, and on lua and the interpreter some strings do not read back as the same number

`Float64.toString` has no doc comment
(`frontend/src/commonMain/resources/core/core.temper:1635`), so nothing says
what it should produce. Every backend writes its own format. The program
prints `x.toString()` for 13 values and checks `s.toFloat64() == x`:

```temper
let show(x: Float64): Void {
  let s = x.toString();
  let back = do {
    if (s.toFloat64() == x) { "reads back" } else { "reads back as a different number" }
  } orelse "does not parse";
  console.log("${s}  ${back}");
}
```

| value | js | py | java | lua | rust | cpp | interp |
|---|---|---|---|---|---|---|---|
| `100.0` | 100.0 | 100.0 | 100.0 | 100.0 | 100.0 | 1.0e+02 | 100.0 |
| `1.5` | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 |
| `0.1 + 0.2` | 0.30000000000000004 | 0.30000000000000004 | 0.30000000000000004 | 0.3 (2) | 0.30000000000000004 | 0.30000000000000004 | 0.3000000000000000 (2) |
| `1.0 / 3.0` | 0.3333333333333333 | 0.3333333333333333 | 0.3333333333333333 | 0.3333333333333333 | 0.3333333333333333 | 0.3333333333333333 | 0.3333333333333333 |
| `0.000001` | 0.000001 | 1.0e-06 | 1.0e-6 | 1.0e-6 | 1e-6 | 1.0e-06 | 1.0e-6 |
| `1.0e-7` | 1.0e-7 | 1.0e-07 | 1.0e-7 | 1.0e-7 | 1e-7 | 1.0e-07 | 1.0e-7 |
| `123456789.0` | 123456789.0 | 123456789.0 | 1.23456789e+8 | 123456789.0 | 1.23456789e+8 | 123456789.0 | 1.23456789e+8 |
| `1.0e15` | 1000000000000000.0 | 1000000000000000.0 | 1.0e+15 | 1000000000000000.0 | 1.0e+15 | 1.0e+15 | 1.0e+15 |
| `1.0e16` | 10000000000000000.0 | 1.0e+16 | 1.0e+16 | 1.0e+16 | 1.0e+16 | 1.0e+16 | 1.0e+16 |
| `1.0e21` | 1.0e+21 | 1.0e+21 | 1.0e+21 | 1.0e+21 | 1.0e+21 | 1.0e+21 | 1.0e+21 |
| `1.7976931348623157e308` | 1.7976931348623157e+308 | same | same | 1.797693134862316e+308 (2) | same | same | same |
| `5.0e-324` | 5.0e-324 | 5.0e-324 | 4.9e-324 | 4.940656458412465e-324 | 5e-324 | 5.0e-324 (3) | 4.9e-324 |
| `-0.0` | -0.0 | -0.0 | -0.0 | -0.0 | -0.0 | -0.0 | -0.0 |

(2) reads back as a different number. (3) does not parse on cpp; that is
`String.toFloat64` rejecting subnormals, filed separately.

Every other cell reads back as the same number on its own backend.

Two kinds of problem show here.

Lossy output. lua formats with `%.16g`, which is not enough digits for every
double: `0.1 + 0.2` prints `0.3`, and the largest double prints a value that
parses to a different number. The interpreter formats with 16 fixed decimal
places, so `0.1 + 0.2` prints `0.3000000000000000`, which also reads back as
`0.3`. Since the interpreter is what runs compile-time code and the REPL,
its strings are the ones a developer sees there.

Format differences. For the same number, backends disagree on whether to use
an exponent (`123456789.0` versus `1.23456789e+8`; `1000000000000000.0`
versus `1.0e+15`; cpp's `1.0e+02` for `100.0`), on zero-padding the exponent
(`1.0e-06` on py and cpp), on keeping `.0` in the mantissa (`1e-6` on rust),
and on how many digits to give a subnormal (`5.0e-324`, `4.9e-324`,
`4.940656458412465e-324`, `5e-324`). All of these read back correctly, but a
test that compares formatted output, or a program that writes numbers into
text that another backend reads, sees different bytes.

```sh
./repro.sh 32-float64-tostring-per-backend/float-tostring lua
./repro.sh 32-float64-tostring-per-backend/float-tostring cpp
./repro.sh 32-float64-tostring-per-backend/float-tostring js
```

The interpreter column comes from the REPL:

```sh
echo 'import("float-tostring");' | "$TEMPER" repl -w 32-float64-tostring-per-backend/float-tostring
```

## Expected

A documented format that every backend produces. At least, the shortest
string that reads back as the same double, which js, py, java, rust and cpp
already give, with differences only in layout. The js runtime has a
`TODO(mikesamuel, issue#579): need functional test to nail down double
formatting thresholds` on this function
(`be-js/src/commonMain/resources/lang/temper/be/js/temper-core/float.js:103`).

## Notes

Where each backend formats, at `ffba652a`:

- js: `Number.prototype.toString`, then `.0` added
  (`be-js/.../temper-core/float.js:102-118`).
- py: `str(value)` then `_ensure_dot_frac`
  (`be-py/.../temper_core/__init__.py:613-622`); Python's `repr` switches to
  exponent form below `1e-4` and at `1e16`, and pads the exponent to two
  digits.
- java: `Double.toString`, with the exponent rewritten
  (`be-java/.../temper/core/Core.java:366`); `Double.toString` uses an
  exponent outside `[1e-3, 1e7)`.
- lua: `string.format("%.16g", n)`
  (`be-lua/src/commonMain/resources/lang/temper/be/lua/temper-core/init.lua:467-490`).
- rust: `x.to_string()` inside `[0.001, 1e7)`, otherwise `format!("{x:e}")`
  with `.0` added only when `abs > 1`
  (`be-rust/src/commonMain/resources/lang/temper/be/rust/temper-core/src/float64.rs:80`).
- cpp: `ostringstream` with increasing precision until `strtod` reads it
  back (`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/float64.hpp:152-190`);
  `%g` style, so `100.0` at precision 1 is `1e+02`.
- interpreter: `formatDouble(d, decimalPlaces = 16)`
  (`frontend/src/commonMain/kotlin/lang/temper/frontend/core/FloatFns.kt:72-77`,
  `common/src/commonMain/kotlin/lang/temper/common/FormatDouble.kt:10`,
  `F64_DECIMAL_DIGITS` in `StandardLibraryHelpers.kt:445`).

The backends' own `toString` was checked not to be folded at compile time:
`(0.1 + 0.2).toString()` as a top-level constant prints
`0.30000000000000004` on js and py.

Not checked: csharp, NaN and the infinities (division by zero bubbles, and
the program does not build them another way).
