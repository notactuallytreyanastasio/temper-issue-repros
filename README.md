# Temper issue reproductions

Small Temper libraries that reproduce four bugs in the Temper compiler, one
directory per bug. Each was checked against
[temperlang/temper](https://github.com/temperlang/temper) at `e9ff0d25`
(main on 2026-10-02) with the js and py backends, and each shows on both.

| Directory | Issue | What happens |
|---|---|---|
| [01-class-equality](01-class-equality) | [#508](https://github.com/temperlang/temper/issues/508), fix [#515](https://github.com/temperlang/temper/pull/515) | `==` or `when` on class instances: a diagnostic about `Int32`, then an internal compiler message at run time |
| [02-loop-condition-crash](02-loop-condition-crash) | [#509](https://github.com/temperlang/temper/issues/509), fix [#512](https://github.com/temperlang/temper/pull/512) | a loop whose condition fails while the compiler evaluates it crashes the compiler |
| [03-for-of-at-compile-time](03-for-of-at-compile-time) | [#510](https://github.com/temperlang/temper/issues/510), fix [#513](https://github.com/temperlang/temper/pull/513) | `for (let x of xs)` in a function the compiler evaluates fails the build |
| [04-rejected-assignment-emitted](04-rejected-assignment-emitted) | [#511](https://github.com/temperlang/temper/issues/511), draft [#514](https://github.com/temperlang/temper/pull/514) | a rejected assignment is emitted as written, and the failed build's output runs |

## Running a case

Build the CLI from upstream (JDK 21; `node` for js, `python3` for py):

```sh
git clone https://github.com/temperlang/temper && cd temper
git checkout e9ff0d25
./gradlew :cli:installDist
export TEMPER=$PWD/cli/build/install/temper/bin/temper
```

Then, from this repository:

```sh
./repro.sh 01-class-equality/when-on-class js
./repro.sh 02-loop-condition-crash/not-equal py
```

Each case directory is one library named after the directory. Its `how`
file says whether the case is a `run`, a `test` or a `build`, and
`repro.sh` runs that with the backend you give it (js if you give none).
