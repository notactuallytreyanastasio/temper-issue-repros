# `temper run -b java` and `temper test -b java` reject a JDK whose version has four parts

Homebrew's `openjdk@21` reports its version as `21.0.12.1`. With that JDK on
`PATH`, `temper run -b java` and `temper test -b java` stop before running
anything, with an uncaught `SemVerParseError` caused by
`NumberFormatException: For input string: "21.0.12.1"`, and exit 1. With
Homebrew's `openjdk@27`, which reports `27`, the same commands pass.
`temper build -b java` is not affected, because it does not check the JDK.

## The two JDKs

```
$ /opt/homebrew/opt/openjdk@21/bin/java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment Homebrew (build 21.0.12.1)
OpenJDK 64-Bit Server VM Homebrew (build 21.0.12.1, mixed mode, sharing)

$ /opt/homebrew/opt/openjdk@27/bin/java -version
openjdk version "27" 2026-09-15
OpenJDK Runtime Environment Homebrew (build 27)
OpenJDK 64-Bit Server VM Homebrew (build 27, mixed mode, sharing)
```

`javac -version` and `jshell --version` from `openjdk@21` print `javac 21.0.12.1`
and `jshell 21.0.12.1`.

## Source

[`hello/src/main.temper.md`](hello/src/main.temper.md), a `run` case:

```temper
console.log("hello from java");
```

[`one-test/src/main.temper.md`](one-test/src/main.temper.md), a `test` case:

```temper
test("one plus one") { test =>
  assert(1 + 1 == 2) { "arithmetic" }
}
```

## Commands and output

The CLI itself runs on JDK 21 (`JAVA_HOME=/opt/homebrew/opt/openjdk@21`) in
every run below; only `PATH` changes. The `grep` drops the stack frames, and
the shell is zsh, where `pipestatus[1]` is the exit code of `repro.sh`.

```
$ PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH ./repro.sh 14-java-four-part-jdk-version/hello java 2>&1 | grep -v '^	at '; echo "exit=${pipestatus[1]}"
Exception in thread "main" lang.temper.be.cli.SemVerParseError: /opt/homebrew/opt/openjdk@21/bin/java didn't return a parseable version
Caused by: java.lang.NumberFormatException: For input string: "21.0.12.1"
	... 28 more
exit=1

$ PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH ./repro.sh 14-java-four-part-jdk-version/one-test java 2>&1 | grep -v '^	at '; echo "exit=${pipestatus[1]}"
Exception in thread "main" lang.temper.be.cli.SemVerParseError: /opt/homebrew/opt/openjdk@21/bin/java didn't return a parseable version
Caused by: java.lang.NumberFormatException: For input string: "21.0.12.1"
	... 28 more
exit=1

$ PATH=/opt/homebrew/opt/openjdk@27/bin:$PATH ./repro.sh 14-java-four-part-jdk-version/hello java; echo "exit=$?"
hello from java

exit=0

$ PATH=/opt/homebrew/opt/openjdk@27/bin:$PATH ./repro.sh 14-java-four-part-jdk-version/one-test java; echo "exit=$?"
Tests passed: 1 of 1
exit=0
```

The frames that the `grep` removed include these, from the trace for `hello`:

```
	at lang.temper.be.java.Java17Specifics$JavaTool.checkVersion(JavaSpecifics.kt:211)
	at lang.temper.be.java.JavaSpecifics.validate(JavaSpecifics.kt:42)
	at lang.temper.be.java.Java17Specifics$JavaTool.checkVersion$lambda$2(JavaSpecifics.kt:209)
	at lang.temper.be.java.Java17Specifics$JavaTool.checkVersion(JavaSpecifics.kt:207)
```

## Expected

The run prints `hello from java` and the test passes with JDK `21.0.12.1`,
as they do with JDK `27`. JEP 322 defines the version string as
`$FEATURE.$INTERIM.$UPDATE.$PATCH`, so four parts are a valid JDK version.
A version the check cannot parse would also be better reported as a CLI
error than as an uncaught exception.

## Notes

Checked against temperlang/temper `e9ff0d25`. By reading the code:

`be-java/src/commonMain/kotlin/lang/temper/be/java/JavaSpecifics.kt:203-213`
(`Java17Specifics.JavaTool.checkVersion`) takes the quoted version with
`Regex("""[\w ]+"([\d.]+)""")` (line 220) and parses it with `SemVer(version)`
(`name/src/commonMain/kotlin/lang/temper/name/SemVer.kt:148`), which accepts
three parts. On failure it falls back to `SemVer(parseInt(version.trim()), 0, 0)`
at line 209, which handles a single number such as `"23"` and nothing else.
`"21.0.12.1"` fails both, and `checkMin`
(`be/src/commonMain/kotlin/lang/temper/be/cli/RResultExt.kt:32-36`) turns
the failure into `SemVerParseError`.

The comment above the regex (line 215) lists the version strings it was written for:
`"23"`, `"1.8.0_372"`, `"17.0.7"`, `"17.0.5"`. None has four parts.

Not checked: other JDK distributions that print four parts (for example
`17.0.x.y` builds from other vendors), and Windows.

No upstream issue or PR found for this (searched issues and PRs for
`version`, `JDK`, `SemVer`, `java version`). A fix exists on a fork:
[notactuallytreyanastasio/temper#4](https://github.com/notactuallytreyanastasio/temper/pull/4)
(open, based on `e9ff0d25`), part 3, changes the fallback to take the first
three dot-separated parts and pad with zeros. Its description reports
`Java17FunctionalTest` passing 64 of 64 with `openjdk@21` on `PATH`; I did
not run that branch here.

[05-async-blocks-race](../05-async-blocks-race) works around this with a
`run-java.sh` that builds with the CLI and runs `javac` and `java` by hand.
