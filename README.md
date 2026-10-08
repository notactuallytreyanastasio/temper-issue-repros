# Temper issue reproductions

Small Temper libraries that reproduce bugs in the Temper compiler, one
directory per bug. Each was checked against
[temperlang/temper](https://github.com/temperlang/temper) at `e9ff0d25`
(main on 2026-10-02); each case's README says which backends it ran on.

| Directory | Issue | What happens |
|---|---|---|
| [01-class-equality](01-class-equality) | [#508](https://github.com/temperlang/temper/issues/508), fix [#515](https://github.com/temperlang/temper/pull/515) | `==` or `when` on class instances: a diagnostic about `Int32`, then an internal compiler message at run time |
| [02-loop-condition-crash](02-loop-condition-crash) | [#509](https://github.com/temperlang/temper/issues/509), fix [#512](https://github.com/temperlang/temper/pull/512) | a loop whose condition fails while the compiler evaluates it crashes the compiler |
| [03-for-of-at-compile-time](03-for-of-at-compile-time) | [#510](https://github.com/temperlang/temper/issues/510), fix [#513](https://github.com/temperlang/temper/pull/513) | `for (let x of xs)` in a function the compiler evaluates fails the build |
| [04-rejected-assignment-emitted](04-rejected-assignment-emitted) | [#511](https://github.com/temperlang/temper/issues/511), draft [#514](https://github.com/temperlang/temper/pull/514) | a rejected assignment is emitted as written, and the failed build's output runs |
| [05-async-blocks-race](05-async-blocks-race) | [#516](https://github.com/temperlang/temper/issues/516) | `async` blocks run in parallel on py and java and lose updates to shared state |
| [06-rust-lock-held-across-call](06-rust-lock-held-across-call) | [#517](https://github.com/temperlang/temper/issues/517) | rust: a method call on a field holds the read lock; a write back deadlocks |
| [07-promise-second-waiter-dropped](07-promise-second-waiter-dropped) | [#518](https://github.com/temperlang/temper/issues/518) | rust: a promise resumes only the last block that awaits it |
| [08-promise-complete-resumes-inline](08-promise-complete-resumes-inline) | [#519](https://github.com/temperlang/temper/issues/519) | `complete()` runs the waiter before it returns on rust, py and java |
| [09-cpp-continuation-never-resumes](09-cpp-continuation-never-resumes) | [#520](https://github.com/temperlang/temper/issues/520) | cpp: a block never resumes when top-level code completes its promise |
| [10-await-outside-async](10-await-outside-async) | [#521](https://github.com/temperlang/temper/issues/521) | `await` outside an async block passes the frontend, then each backend fails |
| [11-rust-closure-in-top-level-block](11-rust-closure-in-top-level-block) | [#522](https://github.com/temperlang/temper/issues/522) | rust: a function inside a top-level `if` or `while` cannot read a top-level variable |
| [12-rust-std-name-collisions](12-rust-std-name-collisions) | [#523](https://github.com/temperlang/temper/issues/523) | rust: classes named `Box`, `Option`, `Some`, `None`, `Ok` or `Err` break the output |
| [13-java-exit-abandons-async-work](13-java-exit-abandons-async-work) | [#524](https://github.com/temperlang/temper/issues/524) | java: `main` exits 0 after 10 seconds while an async block still runs |
| [14-java-four-part-jdk-version](14-java-four-part-jdk-version) | [#525](https://github.com/temperlang/temper/issues/525) | `temper run -b java` rejects a JDK version like `21.0.12.1` |
| [15-let-maybe-uninitialized](15-let-maybe-uninitialized) | [#528](https://github.com/temperlang/temper/issues/528) | a `let` assigned a constant on one branch builds and reads as that constant |
| [16-java-recursive-local-reads-field](16-java-recursive-local-reads-field) | [#535](https://github.com/temperlang/temper/issues/535) | java: a recursive local function that reads a field compiles to code javac rejects |
| [17-void-function-ending-in-panic](17-void-function-ending-in-panic) | [#536](https://github.com/temperlang/temper/issues/536) | a `Void` function ending in `panic()` or `bubble()` fails to build on js and rust |
| [18-cpp-argument-order](18-cpp-argument-order) | [#539](https://github.com/temperlang/temper/issues/539) | cpp: call arguments run right to left under x86-64 g++ |

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
