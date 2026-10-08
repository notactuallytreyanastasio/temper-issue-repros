# Comment on #373: Float64 division by zero: which backends bubble at ffba652a

A correction to the description, and the current state at `ffba652a`.

The description treats js as correct. The docs say the opposite.
`docs/for-users/temper-docs/docs/reference/builtins.md`, under `/`
(around line 957), says "Float64 division by zero is a *Bubble* too",
with this example:

```temper
console.log("${ (0.0 /  0.0).toString() orelse "Bubble" }"); //!outputs "Bubble"
console.log("${ (1.0 /  0.0).toString() orelse "Bubble" }"); //!outputs "Bubble"
console.log("${ (1.0 / -0.0).toString() orelse "Bubble" }"); //!outputs "Bubble"
```

Run as a program, that example prints `Bubble` three times on py and rust,
and `NaN`, `Infinity`, `-Infinity` on js, lua, java and cpp. With a
divisor the compiler cannot fold, the split is the same, and `%` follows
`/`:

```temper
let show(a: Float64, b: Float64): String {
  "${(a / b).toString() orelse "Bubble"} ${(a % b).toString() orelse "Bubble"}"
}
var z = 0.0;
z = z;
console.log("1.0 / 0.0: ${show(1.0, z)}");
console.log("0.0 / 0.0: ${show(0.0, z)}");
console.log("1.0 / -0.0: ${show(1.0, -z)}");
```

py and rust:

```
1.0 / 0.0: Bubble Bubble
0.0 / 0.0: Bubble Bubble
1.0 / -0.0: Bubble Bubble
```

js, lua, java and cpp:

```
1.0 / 0.0: Infinity NaN
0.0 / 0.0: NaN NaN
1.0 / -0.0: -Infinity NaN
```

The interpreter bubbles on all three (REPL, with `show` as above:
`"Bubble Bubble | Bubble Bubble | Bubble Bubble"`). That matches the list
in @tjpalmer's comment above, with cpp added to the NaN side. csharp was not run.
A backend on our fork does the same as js.

On js the operator is emitted bare, inside the `try` that `orelse` sets
up, so nothing throws:

```js
try {
  const t_6 = a_2 / b_3;
  t_4 = float64ToString(t_6);
} catch {
  t_4 = "Bubble";
}
```

That comes from `BuiltinOperatorId.DivFltFlt` in
`be-js/src/commonMain/kotlin/lang/temper/be/js/JsSupportNetwork.kt:1731`,
which builds a plain `Js.InfixExpression` with `/`; `ModFltFlt` at line
1742 is the same shape. The interpreter's check is in `divFloatFloatFn`,
`builtin/src/commonMain/kotlin/lang/temper/builtin/BuiltinFuns.kt:940`.

Whichever way this is settled, the docs example above is wrong today on
four of the six backends I ran.
