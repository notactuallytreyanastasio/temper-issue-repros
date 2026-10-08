# lua: a list literal of 250 elements does not load, because every element becomes an argument to one call

A top-level list of 250 strings builds, and then Lua refuses to load the
module:

```temper
let xs = [
  "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9",
  ...
  "s240", "s241", "s242", "s243", "s244", "s245", "s246", "s247", "s248", "s249",
];
console.log(xs.length.toString());
```

```
$ ./repro.sh 45-lua-long-list-literal/two-hundred-fifty lua
.../lua: two-hundred-fifty/init.lua:4: function or expression needs too many registers near ';'
```

The generated line 4 passes each element as an argument to `temper.listof`:

```lua
local temper = require('temper-core');
local console_0, xs, exports;
console_0 = 0.0;
xs = temper.listof('s0', 's1', 's2', ..., 's248', 's249');
```

`temper.listof` is `function temper.listof(...) return {...} end`
(`be-lua/src/commonMain/resources/lang/temper/be/lua/temper-core/init.lua:539`).
A Lua function has at most 255 registers, and a call needs one for the
callee and one per argument, on top of the function's live locals. With
four locals at top level, 249 elements load and 250 do not
([`two-hundred-forty-nine`](two-hundred-forty-nine/src/main.temper.md)
prints `249`). Integers fail at the same count as strings. Inside a
function with two parameters and two locals, 248 elements load and 249 do
not, so the limit is lower the more locals are live.

js and py print the count for both:

```
$ ./repro.sh 45-lua-long-list-literal/two-hundred-fifty js
250
$ ./repro.sh 45-lua-long-list-literal/two-hundred-fifty py
250
```

## Expected

`250`. A table constructor does not hit this: Lua 5.4.9 loads
`local t = {'s0', ..., 's4999'}; print(#t)` and prints `5000`, since it
stores list items into the table in batches. Emitting the literal as a
table, or calling `listof` over chunks, would avoid it.

## Notes

`BuiltinOperatorId.Listify` maps to `listof` in
`be-lua/src/commonMain/kotlin/lang/temper/be/lua/LuaSupportNetwork.kt:92`.
Run with Lua 5.4.9. I did not try Lua 5.1 or LuaJIT, which the backend
also targets (`Lua51Specifics.kt`).

This may be the shape behind #343, whose error comes from a generated
module (`html.lua:2799 ... near ''↧''`), but that issue has no source, so I
cannot say. #13 was about too many locals and was fixed by spilling locals
into a table; that does not cover call arguments.
