# py: `Int.toString(36)` raises ValueError for every value, because the radix check stops at 35

`toString(radix)` on `Int32` and `Int64` is documented as "Supports radix 2
through 36", but on py radix 36 raises a bare `ValueError`, whatever the
number:

```temper
let show(a: Int, b: Int64): Void {
  console.log("Int32 ${a.toString()} in radix 36: ${a.toString(36)}");
  console.log("Int64 ${b.toString()} in radix 36: ${b.toString(36)}");
}
show(35, 35i64);
show(-2147483647 - 1, -9223372036854775807i64 - 1i64);
```

js, java, lua, rust, cpp and the interpreter:

```
Int32 35 in radix 36: z
Int64 35 in radix 36: z
Int32 -2147483648 in radix 36: -zik0zk
Int64 -9223372036854775808 in radix 36: -1y2p0ij32e8e8
```

py:

```
  File ".../temper_core/__init__.py", line 449, in int_to_string
    raise ValueError()
ValueError
```

The first call, `35.toString(36)`, already fails. Radix 2, 10 and 16 on the
same minimum values give the same output on py as on js.

```sh
./repro.sh 36-py-tostring-radix-36/radix-thirty-six py
./repro.sh 36-py-tostring-radix-36/radix-thirty-six js
```

## Expected

`z` and the other lines above, as on the other backends.

## Notes

`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:448`:

```python
def int_to_string(num: int, radix: int = 10) -> str:
    "Implements connected method core.type Int32.toString()."
    if not 2 <= radix < 36:
        raise ValueError()
```

`radix < 36` should be `radix <= 36`. The digit table on line 463 already has
36 symbols. The doc is at
`frontend/src/commonMain/resources/core/core.temper:1503` and `:1572`.

The minimum values are written as `-2147483647 - 1` because the literal
`-2147483648` draws "Int32 value, 2147483648, out of representable bounds"
and the build continues; with that literal, js printed `-1e+31` for radix 2
and `NaN` for radix 36. That looks like a separate problem and is not
covered here.

Not checked: csharp.
