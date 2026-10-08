# Regex literals read `{3}` and `{2,3}` as literal text, though `std/regex` documents them as counted repetition

`/[0-9]{3}/` compiles without a diagnostic to a pattern that matches a
digit followed by the three characters `{3}`. It never matches `"x123y"`:

```
/[0-9]{3}/ on x123y:   no match
/[0-9]{2,3}/ on x123y: no match
/x{3}/ on ax{3}b:      x{3}
Repeat(3, 3) on x123y: 123
```

That is the output on js, py, lua, java, rust and cpp. Building the same
`Repeat` by hand matches `123`, so the regex engine side works; the
literal is parsed wrong. The REPL shows the tree the literal becomes:

```
$ let { ... } = import("std/regex"); /[0-9]{3}/.data
interactive#0: {class: Sequence, items: [{class: CodeSet, items: [{class: CodeRange, min: 48, max: 57}], negated: false},{class: CodePoints, value: "{3}"}]}
$ /a{2,3}?/.data
interactive#1: {class: Sequence, items: [{class: CodePoints, value: "a{2,3"},{class: Repeat, item: {class: CodePoints, value: "}"}, min: 0, max: 1, reluctant: false}]}
```

In the second, the trailing `?` meant "reluctant" and applies to `}`
instead.

## Source

[`brace-count/src/main.temper.md`](brace-count/src/main.temper.md):

```temper
let { ... } = import("std/regex");

let show(re: Regex, s: String): String {
  re.find(s).full.value orelse "no match"
}

console.log("/[0-9]{3}/ on x123y:   ${show(/[0-9]{3}/, "x123y")}");
console.log("/[0-9]{2,3}/ on x123y: ${show(/[0-9]{2,3}/, "x123y")}");
console.log("/x{3}/ on ax{3}b:      ${show(/x{3}/, "ax{3}b")}");
console.log("Repeat(3, 3) on x123y: ${show(new Repeat(/[0-9]/.data, 3, 3).compiled(), "x123y")}");
```

```sh
./repro.sh 20-regex-counted-repetition/brace-count js
```

## Expected

`123` for the first two lines and `no match` for the third, as
`frontend/src/commonMain/resources/std/regex/regex.temper.md` says under
`Repeat`:

> - `{m}` matches exactly `m` repetitions.
> - `{m,n}` matches between `m` and `n`. Missing `n` is a max of infinity.

Failing that, a compile-time error for `{` in a regex literal. Reading it
as literal text gives a pattern that compiles and quietly matches
something else.

## Notes

Regex literals are parsed by `temper-regex-parser`, pinned at `0.3.0` in
`builtin/build.gradle:31` and called from
`builtin/src/commonMain/kotlin/lang/temper/builtin/RegexLiteralMacro.kt:142`.
In 0.3.0, `{` and `}` are ordinary characters. temper-regex-parser main
gained `{n}`, `{n,}` and `{n,m}` in temperlang/temper-regex-parser#27
(`tryParseBraceQuantifier` in `parser.temper`, merged 2026-03-17), but
Maven Central still has 0.3.0 as the latest release, so nothing on Temper
main picks it up. I did not build Temper against parser main, so I have
not checked that the change is enough on its own.

`rgx"..."` literals go through the same parser; I did not run them. csharp
was not run.
