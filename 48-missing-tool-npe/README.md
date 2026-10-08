# `temper test -b lua` with no `lua` on PATH, or `-b rust` with no `cargo`, throws a NullPointerException instead of naming the missing tool

With no `lua` on `PATH`, `temper test -b lua` and `temper run -b lua` stop
with a bare `NullPointerException`:

```
$ temper test -b lua
Exception in thread "main" java.lang.NullPointerException
	at lang.temper.be.cli.CliEnv.get(CliEnv.kt:70)
	at lang.temper.be.lua.Lua51Specifics.runBestEffort(Lua51Specifics.kt:141)
	at lang.temper.be.cli.RunnerSpecifics.runBestEffort(Specifics.kt:81)
	...
```

(`temper run -b lua` fails the same way at `Lua51Specifics.kt:111`.)
rust does the same when `rustc` is on `PATH` and `cargo` is not:

```
Exception in thread "main" java.lang.NullPointerException
	at lang.temper.be.cli.CliEnv.get(CliEnv.kt:70)
	at lang.temper.be.rust.RunRustKt.runCargo(RunRust.kt:57)
```

Every other missing tool I tried is named, though as an uncaught exception
with a stack trace rather than a message:

```
Exception in thread "main" lang.temper.be.cli.CommandNotFound: Command not found; none of [node] were found in [<PATH entries>]
	at lang.temper.be.cli.LocalCliEnv.which$lambda$4(LocalCliEnv.kt:142)
	...
	at lang.temper.be.cli.Specifics.validate(Specifics.kt:37)
```

| backend | tools on PATH | result |
|---|---|---|
| lua | none | `NullPointerException` |
| rust | `rustc` only | `NullPointerException` |
| rust | none | `CommandNotFound` for `rustc` |
| js | none | `CommandNotFound` for `node` |
| js | `node` only | `CommandNotFound` for `npm` |
| py | none | `CommandNotFound` for `python3, python` |
| java | none | `CommandNotFound` for `java` |
| java | `java`, `javac`, `jshell` | `CommandNotFound` for `mvn` |
| cpp | none | `CommandNotFound` for `g++-16, g++-15, g++-14, g++` |
| cpp | `g++` only (no `cmake`) | runs, "Tests passed: 1 of 1" |
| csharp | none | `CommandNotFound` for `dotnet` |

All exit 1. "none" means a `PATH` of a directory with `sed`, `uname` and
similar utilities that the launcher script needs, plus `/bin`.

## Source

Any library does it. [`one-passing-test/src/main.temper.md`](one-passing-test/src/main.temper.md):

```temper
test("passes") { test =>
  assert(1 + 1 == 2) { "arithmetic" }
}
```

```sh
# with no lua on PATH
./repro.sh 48-missing-tool-npe/one-passing-test lua
```

## Expected

A message that names the missing tool, as the `CommandNotFound` cases do,
and preferably without a JVM stack trace for what is a setup problem.

## Notes

From reading the code at `ffba652a`:

`CliEnv.get` is `which(tool).result!!`
(`be/src/commonMain/kotlin/lang/temper/be/cli/CliEnv.kt:70`), so a tool
that `which` cannot find becomes a `NullPointerException`. The other
backends get `CommandNotFound` because `CliEnv.using` calls
`validate().orThrow()` before running (`CliEnv.kt:337`), and
`Specifics.validate` looks up each `VersionedTool` in the backend's `tools`
(`be/src/commonMain/kotlin/lang/temper/be/cli/Specifics.kt:32-58`).
`Lua51Specifics.tools` is empty
(`be-lua/src/commonMain/kotlin/lang/temper/be/lua/Lua51Specifics.kt:239-240`),
and `RustSpecifics.tools` lists only `RustcCommand`, not `CargoCommand`
(`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustSpecifics.kt:43`),
so nothing checks for `lua` or `cargo` before `get` is called.

Two changes would cover it: `get` failing with the `CommandNotFound` that
`which` already carries instead of `!!`, and the lua and rust specifics
listing the tools they run. Neither was tried.

`cmake` was not missed by cpp in this test, so either the cpp test path
does not use it or it is found another way; I did not look.
