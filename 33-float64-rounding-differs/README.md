# Float64 `floor`, `ceil` and `round` give different answers per backend: py returns Python ints, `round` has three tie rules, java's `round` saturates

The same nine inputs through `floor()`, `ceil()` and `round()`:

```temper
let show(s: String): Void {
  let x = s.toFloat64() orelse 0.0;
  let f = x.floor().toString();
  let c = x.ceil().toString();
  let r = x.round().toString();
  console.log("${s}: floor ${f} | ceil ${c} | round ${r}");
}
show("-0.0"); show("-0.4"); show("0.5"); show("2.5"); show("-2.5");
show("0.49999999999999994"); show("1e300"); show("Infinity"); show("NaN");
```

`round` only, plus the cells of `floor` and `ceil` that differ from js:

| input | js | interp | rust, cpp | java | lua | py |
|---|---|---|---|---|---|---|
| `-0.0` | -0.0 | -0.0 | -0.0 | 0.0 | 0.0 (floor, ceil 0.0) | 0.0 (floor, ceil 0.0) |
| `-0.4` | -0.0 | -0.0 | -0.0 | 0.0 | 0.0 (ceil 0.0) | 0.0 (ceil 0.0) |
| `0.5` | 1.0 | 0.0 | 1.0 | 1.0 | 1.0 | 0.0 |
| `2.5` | 3.0 | 2.0 | 3.0 | 3.0 | 3.0 | 2.0 |
| `-2.5` | -2.0 | -2.0 | -3.0 | -2.0 | -2.0 | -2.0 |
| `0.49999999999999994` | 0.0 | 0.0 | 0.0 | 0.0 | 1.0 | 0.0 |
| `1e300` | 1.0e+300 | 1.0e+300 | 1.0e+300 | 9.223372036854776e+18 | 1.0e+300 | a 301-digit integer, `1000000000000000052504...540160.0` (floor and ceil the same) |
| `Infinity` | Infinity | Infinity | Infinity | 9.223372036854776e+18 | Infinity | OverflowError from `floor` |
| `NaN` | NaN | NaN | NaN | 0.0 | NaN | not reached |

js's full output, which rust and cpp match except for `round(-2.5)`:

```
-0.0: floor -0.0 | ceil -0.0 | round -0.0
-0.4: floor -1.0 | ceil -0.0 | round -0.0
0.5: floor 0.0 | ceil 1.0 | round 1.0
2.5: floor 2.0 | ceil 3.0 | round 3.0
-2.5: floor -3.0 | ceil -2.0 | round -2.0
0.49999999999999994: floor 0.0 | ceil 1.0 | round 0.0
1e300: floor 1.0e+300 | ceil 1.0e+300 | round 1.0e+300
Infinity: floor Infinity | ceil Infinity | round Infinity
NaN: floor NaN | ceil NaN | round NaN
```

py stops at `Infinity`:

```
    f_5: 'str7' = _float64_to_string_102(_floor_101(x_4))
OverflowError: cannot convert float infinity to integer
```

Three things are going on.

1. py maps `floor` and `ceil` to `math.floor` and `math.ceil`, and `round` to
   the builtin `round`, all of which return a Python `int` for a float
   argument. That loses the sign of zero, turns `1e300` into its exact
   integer, raises `OverflowError` for infinities and `ValueError` for NaN
   (checked in Python 3.14: `math.floor(float('nan'))` gives
   `ValueError: cannot convert float NaN to integer`), and makes a
   `Float64`-typed value an `int` at run time. `floor` and `round` cannot
   bubble, so the error is not catchable with `orelse`.
2. `round` breaks ties three ways: toward positive infinity on js, java and
   lua (`-2.5` gives `-2.0`), away from zero on rust and cpp (`-3.0`), and to
   even on py and the interpreter (`0.5` gives `0.0`, `2.5` gives `2.0`).
   lua computes `floor(x + 0.5)`, so `0.49999999999999994` rounds to `1.0`.
3. java's `round` is `Math.round(double)`, which returns a `long`; 1e300 and
   Infinity saturate to `Long.MAX_VALUE` and NaN becomes `0`.

lua also drops the sign of zero from `floor` and `ceil`.

```sh
./repro.sh 33-float64-rounding-differs/rounding-edges py
./repro.sh 33-float64-rounding-differs/rounding-edges js
./repro.sh 33-float64-rounding-differs/rounding-edges java
```

## Expected

One answer per input on every backend, and a `Float64` result. `floor`, `ceil` and `round` have no doc comments
(`frontend/src/commonMain/resources/core/core.temper:1665`, `:1680`, `:1711`),
so the tie rule is not specified. js, rust and cpp agree on everything except
the tie for negative halves; IEEE 754 `roundToIntegralTiesToAway` matches
rust and cpp.

## Notes

- py: `PySupportNetwork.kt:448` (`ceil` from `math`), `:453` (`floor` from
  `math`), `:460` (`round` from builtins), all in
  `be-py/src/commonMain/kotlin/lang/temper/be/py/`.
- java: `float64Round` is `Math.round(...)`
  (`be-java/src/commonMain/kotlin/lang/temper/be/java/JavaSupportNetwork.kt:803-805`).
- lua: `temper.float64_floor = math.floor`, `temper.float64_ceil = math.ceil`
  and `float64_round` is `math_floor(x + 0.5)`
  (`be-lua/src/commonMain/resources/lang/temper/be/lua/temper-core/init.lua:362`,
  `:365`, `:428-431`). Lua 5.4's `math.floor` returns an integer when the
  result fits, which would explain `0.0` for `-0.0`; from reading.
- interpreter: `kotlin.math.round`, which rounds half to even
  (`frontend/src/commonMain/kotlin/lang/temper/frontend/core/FloatFns.kt:185-189`).
- The functional test `types/float/ops` checks `pi.round()` and
  `(-pi).round()`, which have no ties.

Not checked: csharp.
