# `temper test` prints a "Test failed" line for one failing test per run, because every failure is logged at the same unknown position

Comment on [#505](https://github.com/temperlang/temper/issues/505),
which reports the same symptom on csharp and lua and asks whether a bug now
shows only one message. It is not backend-specific. With three failing
tests, every backend prints one `Test failed` line, and the count below it
includes all three:

```
$ temper test -b js
Test failed (js): first fails - first message
Tests passed: 1 of 4
Test failed
```

The same on py, lua and cpp (the first test) and on java and rust (the
third, the order their reports list them in). The junit XML each backend
writes has all three `<failure>` elements, so the results reach the CLI;
the lines are dropped when they are printed.

## Source

[`three-failing-tests/src/main.temper.md`](three-failing-tests/src/main.temper.md):

```temper
test("first fails") { test =>
  assert(1 == 2) { "first message" }
}

test("second fails") { test =>
  assert(1 == 3) { "second message" }
}

test("third fails") { test =>
  assert(1 == 4) { "third message" }
}

test("fourth passes") { test =>
  assert(1 == 1) { "unreachable" }
}
```

```sh
./repro.sh 53-test-failed-shown-once/three-failing-tests js
./repro.sh 53-test-failed-shown-once/three-failing-tests py
```

## Cause

`tallyResults` logs each failure as a `LogEntry` at `unknownPos`
(`tooling/src/commonMain/kotlin/lang/temper/tooling/buildrun/TestTally.kt:156-160`).
The console sink, `ConsoleBackedContextualLogSink`, runs every entry
through a `PositionFilter` unless it was built with
`allowDuplicateLogPositions` (`format/src/commonMain/kotlin/lang/temper/format/ConsoleBackedContextualLogSink.kt:71-80`),
and `PositionFilter.allow` passes a position only the first time it is seen
at a given level or when the level rises
(`log/src/commonMain/kotlin/lang/temper/log/PositionFilter.kt:9-16`). Every
`TestFailed` is `Log.Error` at `unknownPos`, so the second and later ones
are dropped. With several backends in one run, the first failure of the
first backend to report is the only line, which matches the csharp-only
line in #505.

I checked this by building the CLI at `ffba652a` with one line added at the
top of `PositionFilter.allow`:

```kotlin
if (pos == unknownPos) { return true }
```

With that, the same case prints all three on js, py, java, rust, lua and
cpp:

```
Test failed (js): first fails - first message
Test failed (js): second fails - second message
Test failed (js): third fails - third message
Tests passed: 1 of 4
Test failed
```

That line is a probe, not a proposed fix: it would also let through any
other repeated message at the unknown position. Logging `TestFailed` through
a path that skips the filter, or giving each failure a position of its own,
would be narrower. I did not check what else logs at `unknownPos`.

The "-74 not run" count for cpp in #505 is a different problem and this
does not touch it. csharp was not run (no `dotnet` here).
