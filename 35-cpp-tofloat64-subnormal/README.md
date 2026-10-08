# cpp: `String.toFloat64` bubbles on subnormal, underflowing and overflowing inputs, because `std::stod` throws on range errors

```temper
let show(s: String): Void {
  let got = do { s.toFloat64().toString() } orelse "bubble";
  console.log("${s} => ${got}");
}
show("2.2250738585072014e-308");
show("2.225e-308");
show("1e-310");
show("5e-324");
show("1e-400");
show("1e400");
```

| input | js | java | rust | lua | interp | py | cpp |
|---|---|---|---|---|---|---|---|
| `2.2250738585072014e-308` (smallest normal) | parses | parses | parses | parses | parses | parses | parses |
| `2.225e-308` (subnormal) | 2.225e-308 | 2.225e-308 | 2.225e-308 | 2.225e-308 | 2.225e-308 | 2.225e-308 | bubble |
| `1e-310` | 1.0e-310 | 1.0e-310 | 1e-310 | 9.999999999999969e-311 | 1.0e-310 | 1.0e-310 | bubble |
| `5e-324` | 5.0e-324 | 4.9e-324 | 5e-324 | 4.940656458412465e-324 | 4.9e-324 | 5.0e-324 | bubble |
| `1e-400` | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | bubble |
| `1e400` | Infinity | Infinity | Infinity | Infinity | Infinity | bubble | bubble |

cpp's own `Float64.toString` writes `5.0e-324` for the smallest double, and
cpp cannot read that string back.

```sh
./repro.sh 35-cpp-tofloat64-subnormal/parse-subnormal cpp
./repro.sh 35-cpp-tofloat64-subnormal/parse-subnormal js
```

## Expected

The nearest double, as on js, java, rust, lua and the interpreter: the
subnormal value for the three subnormal inputs, `0.0` for `1e-400`. The doc
says "Supports numeric JSON format plus Infinity and NaN"
(`frontend/src/commonMain/resources/core/core.temper:632`); all six inputs
are valid JSON numbers.

`1e400` is less clear. Five backends give `Infinity`; py and cpp bubble. JSON
does not say, and the doc does not either. py bubbles on purpose: its
`string_to_float64` rejects an infinite result unless the input ends with
`Infinity`
(`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:748`).
It is listed here so the choice can be made once.

## Notes

`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/string.hpp:306-314`:

```cpp
try {
    return std::stod(trimmed);
}
catch (const TemperBubble&) {
    throw;
}
catch (const std::exception&) {
    bubble<double>("invalid float");
}
```

`std::stod` calls `strtod` and throws `std::out_of_range` when `strtod` sets
`errno` to `ERANGE`, which it does for a result that underflows, including a
subnormal result, as well as for overflow. The input has already passed the
grammar check above that line, so only the range error is left. Calling
`std::strtod` directly and ignoring `ERANGE` would return the subnormal,
`0.0` or `HUGE_VAL`; that is from reading, not tried.

Run with Apple clang on macOS arm64; the `ERANGE` behavior for subnormal
results is the same in glibc as far as its documentation says, but that was
not run. Not checked: csharp.
