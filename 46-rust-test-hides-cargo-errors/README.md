# `temper test -b rust` reports "0 of N (N not run)" and exits 0 when the crate does not compile, and prints none of cargo's errors

When the generated Rust does not compile, `temper test -b rust` prints one
line and exits with status 0:

```
$ temper test -b rust
Tests passed: 0 of 2 (2 not run)
$ echo $?
0
```

cargo's error is not shown. It is in
`temper.out/rust/does-not-compile-on-rust/stderr.txt`, and `cargo test` in
that directory prints it:

```
error: literal out of range for `i32`
  --> src/mod.rs:13:12
   |
13 |     return 3049323471 as i32;
   |            ^^^^^^^^^^
   |
   = note: the literal `3049323471` does not fit into the type `i32` whose range is `-2147483648..=2147483647`
```

`temper run -b rust` on the same code does report it: it prints the
`CommandFailed` block with cargo's stderr, including the error above, and
exits 1. js runs both tests and passes them.

## Source

[`does-not-compile-on-rust/src/main.temper.md`](does-not-compile-on-rust/src/main.temper.md):

```temper
export let k(): Int { 0xb5c0fbcfi64.toInt32Unsafe() }

test("k is the low 32 bits") { test =>
  assert(k() == -1245643825) { "got ${k().toString()}" }
}

test("a test that would pass") { test =>
  assert(true) { "unreachable" }
}
```

The constant is only a way to get Rust that does not compile (rust emits
`3049323471 as i32`, which rustc rejects under `overflowing_literals`);
any compile error gives the same report.

```sh
./repro.sh 46-rust-test-hides-cargo-errors/does-not-compile-on-rust rust
./repro.sh 46-rust-test-hides-cargo-errors/does-not-compile-on-rust js
```

## Expected

The cargo errors on the console and a non-zero exit, as `temper run -b rust`
gives.

## Notes

`runTests` in `be-rust/src/commonMain/kotlin/lang/temper/be/rust/RunRust.kt:72-93`
turns any `CommandFailed` from `cargo test` into junit XML with
`cargoTestToJunitXml`. When the crate does not compile, cargo's stdout has
no test lines, so the parser counts 0 total, 0 passed, 0 failed. Its
consistency check (`RunRust.kt:151`, `passed + failed == total && ...`)
holds for all zeros, and it returns XML for an empty suite. `tallyResults`
prints the failed command only when there is no junit XML
(`tooling/src/commonMain/kotlin/lang/temper/tooling/buildrun/TestTally.kt:131-139`),
and with XML present it counts 0 failures and sets `ok`, which is why the
exit status is 0.

I checked this by building the CLI at `ffba652a` with one more case in that
`when` in `runTests`, so a failed `cargo test` whose stdout has no
`running N tests` line keeps its failure:

```kotlin
failure != null && (failure.effort as Effort).stdout.lines().none { regexTestTotal.find(it) != null } -> null
```

With it, the case prints the `CommandFailed` block with the rustc error and
exits 1, and a crate that compiles and has three failing tests still goes
through the junit path and reports "Tests passed: 1 of 4".
That was a probe; I did not run the rest of the test suite with it.

The Rust literal bug itself is a separate issue, not covered here.
