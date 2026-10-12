# `new Date(2023, 4, 31)` is 1 May on js and 31 April on cpp, and each backend's `Date.fromIsoString` accepts a different set of strings

std/temporal says a `Date` constructor bubbles on a day that does not
exist. The interpreter, rust, java and py do. js rolls the date over
into a real one, so `new Date(2023, 4, 31)` is 2023-05-01. cpp stores
whatever it is given, so the same call is a `Date` for 31 April, and
`new Date(2023, 6, -1)` prints as `2023-06-0-1`. `fromIsoString` is
worse: six backends accept six different sets of strings, and js reads
`"96-03-31"` as 1996 and the Arabic-Indic year `"١٥٩٦-03-31"` as 2001.
On js the answer also depends on the machine's timezone: in Tokyo,
`Date.fromIsoString("1596-3-31")` is 30 March.

[`dates`](dates/src/main.temper.md) builds dates and parses strings, and
prints each result or `bubble`:

```temper
let make(y: Int, m: Int, d: Int): Void {
  let shown = do {
    let date = new Date(y, m, d);
    "${date.toString()} weekday ${date.dayOfWeek.toString()}"
  } orelse "bubble";
  console.log("new Date(${y.toString()}, ${m.toString()}, ${d.toString()}): ${shown}");
}
make(2023, 4, 31);
...
let parse(s: String): Void {
  let shown = do { Date.fromIsoString(s).toString() } orelse "bubble";
  console.log("fromIsoString \"${s}\": ${shown}");
}
parse("96-03-31");
...
```

`-` means it bubbled, and `wN` is `dayOfWeek`. The first two rows of
each half are controls.

| call | interp | rust | java | py | js | cpp |
|---|---|---|---|---|---|---|
| `new Date(1600, 2, 29)` | `1600-02-29 w2` | `1600-02-29 w2` | `1600-02-29 w2` | `1600-02-29 w2` | `1600-02-29 w2` | `1600-02-29 w2` |
| `new Date(2023, 4, 30)` | `2023-04-30 w7` | `2023-04-30 w7` | `2023-04-30 w7` | `2023-04-30 w7` | `2023-04-30 w7` | `2023-04-30 w0` |
| `new Date(1900, 2, 29)` | - | - | - | - | `1900-03-01 w4` | `1900-02-29 w4` |
| `new Date(2023, 4, 31)` | - | - | - | - | `2023-05-01 w1` | `2023-04-31 w1` |
| `new Date(2023, 0, 1)` | - | - | - | - | `2022-12-01 w4` | - |
| `new Date(2023, 6, -1)` | - | - | - | - | `2023-05-30 w2` | `2023-06-0-1 w2` |
| `new Date(12345, 1, 2)` | `12345-01-02 w2` | `12345-01-02 w2` | `+12345-01-02 w2` | - | `+012345-01-02 w2` | `12345-01-02 w2` |
| `fromIsoString("1596-03-31")` | `1596-03-31` | `1596-03-31` | `1596-03-31` | `1596-03-31` | `1596-03-31` | `1596-03-31` |
| `fromIsoString("0012-11-10")` | `0012-11-10` | `0012-11-10` | `0012-11-10` | `0012-11-10` | `0012-11-10` | `0012-11-10` |
| `fromIsoString("96-03-31")` | - | - | - | - | `1996-03-31` | `0096-03-31` |
| `fromIsoString("1596-3-31")` | - | - | - | - | `1596-03-31` | `1596-03-31` |
| `fromIsoString("1596-03-3")` | - | - | - | - | `1596-03-03` | `1596-03-03` |
| `fromIsoString("1596-02-30")` | - | - | - | - | `1596-03-01` | `1596-02-30` |
| `fromIsoString("1596-03-31 ")` | - | - | - | - | `1596-03-31` | `1596-03-31` |
| `fromIsoString(" 1596-03-31")` | `1596-03-31` | `1596-03-31` | - | - | `1596-03-31` | `1596-03-31` |
| `fromIsoString("+1596-03-31")` | `1596-03-31` | `1596-03-31` | - | - | `1596-03-31` | `1596-03-31` |
| `fromIsoString("15960331")` | - | - | - | `1596-03-31` | - | - |
| `fromIsoString("12345-01-02")` | `12345-01-02` | `12345-01-02` | - | - | `+012345-01-02` | `12345-01-02` |
| `fromIsoString("١٥٩٦-03-31")` | `1596-03-31` | - | - | - | `2001-03-31` | - |

Besides validation:

- `dayOfWeek` agrees everywhere except cpp, which gives `0` for Sunday,
  2023-04-30, where the documented ISO number is `7`.
- A five-digit year prints as `+012345-01-02` on js and `+12345-01-02`
  on java, where the others print `12345-01-02`. py cannot make the date
  at all.

The table was run in America/New_York. js reads every string that is
not exactly `YYYY-MM-DD` as local midnight and then takes the UTC date,
so east of UTC those dates move back a day. The `fromIsoString` rows on
js with `TZ=Asia/Tokyo`:

```
fromIsoString "1596-03-31": 1596-03-31
fromIsoString "0012-11-10": 0012-11-10
fromIsoString "96-03-31": 1996-03-30
fromIsoString "1596-3-31": 1596-03-30
fromIsoString "1596-03-3": 1596-03-02
fromIsoString "1596-02-30": 1596-03-01
fromIsoString "1596-03-31 ": 1596-03-30
fromIsoString " 1596-03-31": 1596-03-30
fromIsoString "+1596-03-31": 1596-03-30
fromIsoString "15960331": bubble
fromIsoString "12345-01-02": +012345-01-01
fromIsoString "١٥٩٦-03-31": 2001-03-30
```

```sh
TZ=Asia/Tokyo ./repro.sh 64-date-validation-per-backend/dates js
./repro.sh 64-date-validation-per-backend/dates interp
./repro.sh 64-date-validation-per-backend/dates js
./repro.sh 64-date-validation-per-backend/dates cpp
./repro.sh 64-date-validation-per-backend/dates py
```

Run on node 24.19.0 and Python 3.14.6. java ran under JDK 27, whose
version string is one part, because `temper run -b java` cannot parse
the JDK 21 here (`21.0.12.1`,
[#525](https://github.com/temperlang/temper/issues/525)). lua and
csharp ran after the issue was filed; see the end.

## Expected

What `frontend/src/commonMain/resources/std/temporal/temporal.temper.md`
documents and implements, on every backend:

- The constructor (`:112-126`) bubbles unless `1 <= month <= 12` and
  `1 <= day` up to the length of the month, with 29 February only in a
  leap year. So rows 3 to 6 bubble everywhere.
- `fromIsoString` is documented (`:140`) as parsing "an ISO 8601 Date
  string with dashes like "2000-12-21"", and the Temper body (`:142-167`)
  wants a two-character day, a dash, a two-character month, a dash, and
  at least four characters of year, then builds the date with the
  constructor. So `"96-03-31"`, `"1596-3-31"`, `"1596-03-3"`, a trailing
  space, `"15960331"` and `"1596-02-30"` bubble everywhere.
- `toString` (`:128-138`) pads the year to four digits and adds no sign,
  so `12345-01-02`.
- `dayOfWeek` is the ISO weekday number, 7 for Sunday (`:207-219`).

What the Temper body does with a leading space, a `+` or Arabic-Indic
digits in the year depends on `String.toInt32`, which is
[#556](https://github.com/temperlang/temper/issues/556): the
interpreter and rust follow the Temper body and differ only where their
`toInt32` does.

## Notes

From reading, at `ffba652a`:

- js: the constructor here is temper-core's `dateConstructor`
  (`be-js/src/commonMain/resources/lang/temper/be/js/temper-core/date.js:8-17`),
  which calls `setUTCFullYear`, `setUTCMonth(month - 1)` and
  `setUTCDate(day)` on a JS `Date`, and those roll an out-of-range month
  or day into a neighbouring one. (The translator's other form, `new
  Date(Date.UTC(...))`, at
  `be-js/src/commonMain/kotlin/lang/temper/be/js/JsSupportNetwork.kt:814-839`,
  rolls over the same way.) `fromIsoString` is `new
  Date(Date.parse(s))` (`:1350-1381`). For exactly `YYYY-MM-DD`,
  `Date.parse` uses UTC; node still accepts `"1596-02-30"` in that form
  and rolls it to 1 March. Anything else goes to node's fallback parser,
  which accepts it as local time, and the getters then read the UTC
  date. Nothing checks for an invalid `Date` either. `"15960331"` shows
  `bubble` here only because `toString()` became `toISOString()`, which
  throws a RangeError on an invalid `Date`, and the `do`/`orelse` became
  a bare `catch`. `fromIsoString` itself returned a `Date` whose year
  is NaN.
- cpp: `makeDate` (`be-cpp/src/commonMain/resources/lang/temper/be/cpp/core/date.hpp:93-100`)
  stores the three numbers with no check. `fromIso` (`:102-128`) splits
  on dashes and calls `std::stoi` on each part, which skips leading
  spaces and stops at the first non-digit. `getDayOfWeek` (`:30-46`) is
  Sakamoto's method, which numbers Sunday 0, and bubbles on a month
  outside 1 to 12, which is why `new Date(2023, 0, 1)` bubbles on cpp:
  the constructor succeeded and `dayOfWeek` failed.
- py: `Date` is `datetime.date`
  (`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:44`),
  which cannot hold a year past 9999, and `fromIsoString` is
  `date.fromisoformat` (`:636`), which since Python 3.11 also accepts the
  basic format `YYYYMMDD`.
- java: `Date` is `java.time.LocalDate`; the constructor is
  `LocalDate.of` (`be-java/src/commonMain/kotlin/lang/temper/be/java/JavaSupportNetwork.kt:965-971`)
  and `fromIsoString` is `LocalDate.parse` (`:1003-1007`), which wants
  exactly ISO format and writes years past 9999 with a `+`.
- rust connects only `Date.today()`
  (`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustSupportNetwork.kt:792`),
  so its constructor and parser are the translated Temper bodies.
- The `dayOfWeek` doc table (`temporal.temper.md:214`) lists `3` as
  Monday; it is Wednesday. [#608](https://github.com/temperlang/temper/pull/608)
  changes how `dayOfWeek` is computed in the Temper body and does not
  touch any of the above.

## lua and csharp, after filing

lua (5.5.1) and csharp (.NET 10.0.401) are installed here now, so here they are, from the same CLI at `ffba652a`. `-` means it bubbled.

| call | lua | csharp |
|---|---|---|
| new Date(1600, 2, 29) | - | 1600-02-29 w2 |
| new Date(2023, 4, 30) | 2023-04-30 w7 | 2023-04-30 **w0** |
| new Date(1900, 2, 29), (2023, 4, 31), (2023, 0, 1), (2023, 6, -1) | - | - |
| new Date(12345, 1, 2) | 12345-01-02 w2 | - |
| "1596-03-31", "0012-11-10" | accepted | accepted |
| every other string in the case | - | - |

csharp gives 0 for Sunday, as cpp does; the docs say 7.

lua's `-` for 1600-02-29 is not the constructor, which accepts it. It is `dayOfWeek`, which calls `os.time`, and `os.time` on this Lua refuses any year before 1900:

```
$ lua -e 'print(pcall(os.time, {year=1600, month=2, day=28}))'
false	time result cannot be represented in this installation
$ lua -e 'print(pcall(os.time, {year=1900, month=2, day=28}))'
true	-2203916400
```

The case shows it as a bubble only because the constructor and `dayOfWeek` share one `do` block. `dayOfWeek` is not declared to bubble, so the frontend drops an `orelse` around it on its own, and the program dies:

```temper
let d = new Date(1600, 2, 29);
console.log("built ${d.toString()}");
console.log("weekday ${do { d.dayOfWeek.toString() } orelse "bubble"}");
```

```
built 1600-02-29
lua: temper-core/init.lua:1786: time result cannot be represented in this installation
```

The interpreter prints `weekday 2` there. (It also prints `7` for 1900-01-01, which was a Monday; that is the century-year bug PR #608 fixes. lua does not have that bug, because it calls its own `temper.date_dayofweek` rather than std's Temper, which the description of #608 gets wrong.) lua's `fromIsoString` is the strictest here along with csharp: it rejects `" 1596-03-31"`, `"+1596-03-31"` and `"12345-01-02"`, which the interpreter and rust accept.
