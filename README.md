# Temper issue reproductions

Small Temper libraries that reproduce bugs in the Temper compiler, one
directory per bug. Cases 01 to 18 were checked against
[temperlang/temper](https://github.com/temperlang/temper) at `e9ff0d25`
(main on 2026-10-02), and cases 19 on against `ffba652a` (main on
2026-10-08); each case's README says which backends it ran on.

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
| [19-top-level-assignments-reordered](19-top-level-assignments-reordered) | [#540](https://github.com/temperlang/temper/issues/540) | top-level assignments to a `var` run before the statements written above them |
| [20-regex-counted-repetition](20-regex-counted-repetition) | [#541](https://github.com/temperlang/temper/issues/541) | `/[0-9]{3}/` matches the text `{3}`, not three digits |
| [21-async-block-ending-in-if](21-async-block-ending-in-if) | [#542](https://github.com/temperlang/temper/issues/542), fix [#543](https://github.com/temperlang/temper/pull/543) | an async block ending in an `if` after an `await` breaks on java, rust and cpp |
| [22-net-post-content-type](22-net-post-content-type) | fix [#544](https://github.com/temperlang/temper/pull/544) | std/net `post()` ignores its mime type, so each backend sends its own default |
| [23-static-var-assignment](23-static-var-assignment) | pending | `C.n = ...` on a `static var` writes to a string on js and crashes the compiler in a static method |
| [24-static-getter-crash](24-static-getter-crash) | pending | `static get` or `static set` crashes the compiler |
| [25-coalesce-empty-list-any-value](25-coalesce-empty-list-any-value) | pending | `items ?? []` is typed `List<AnyValue>`; java, rust and cpp output does not compile |
| [26-list-of-subtype-as-list-of-supertype](26-list-of-subtype-as-list-of-supertype) | pending | `List<Square>` where `List<Shape>` is expected fails on java and rust, or cpp |
| [27-async-list-local-across-await](27-async-list-local-across-await) | pending | a `List` local kept across an `await` crashes the java, rust and cpp translators |
| [28-py-async-block-ending-in-if](28-py-async-block-ending-in-if) | pending | py: an async block ending in an `if` with no `else` fails to load (`nonlocal`) |
| [29-js-broken-promise-orelse](29-js-broken-promise-orelse) | pending | js: a promise broken before its block awaits it kills node despite `orelse` |
| [30-interp-await-in-loop](30-interp-await-in-loop) | pending | interpreter: an `await` inside a loop body always takes `orelse` |
| [31-net-404-per-backend](31-net-404-per-backend) | pending | std/net: a 404 is a status on js and java, a broken promise on rust, a hang on py |
| [32-float64-tostring-per-backend](32-float64-tostring-per-backend) | pending | `Float64.toString` differs per backend; some lua and interpreter strings do not read back |
| [33-float64-rounding-differs](33-float64-rounding-differs) | pending | `floor`, `ceil` and `round` differ per backend |
| [34-number-parse-not-json](34-number-parse-not-json) | pending | number parsing accepts non-JSON input, and backends disagree on which |
| [35-cpp-tofloat64-subnormal](35-cpp-tofloat64-subnormal) | pending | cpp: `toFloat64` bubbles on subnormal and out-of-range input |
| [36-py-tostring-radix-36](36-py-tostring-radix-36) | pending | py: `toString(36)` raises for every value |
| [37-py-nonlocal-function-var](37-py-nonlocal-function-var) | pending | py: a reassigned function-holding local `var` breaks the import |
| [38-py-self-bounded-type-param](38-py-self-bounded-type-param) | pending | py: `<T extends Ord<T>>` raises NameError on import |
| [39-java-throwing-fn-type-result](39-java-throwing-fn-type-result) | pending | java: a `throws Bubble` function type becomes `Function<String, Result>` |
| [40-java-float64-list-map-to-object](40-java-float64-list-map-to-object) | pending | java: `List<Float64>.map` to an object type does not compile |
| [41-rust-failed-cast-in-nullable-return](41-rust-failed-cast-in-nullable-return) | pending | rust: `v as T` in a `T? throws Bubble` function does not compile |
| [42-rust-int64-literal-cast](42-rust-int64-literal-cast) | pending | rust: an `Int64` literal outside the `i32` range is emitted without `i64` |
| [43-cpp-method-named-keyword](43-cpp-method-named-keyword) | pending | cpp: calling a method named after a C++ keyword crashes the translator |
| [44-cpp-std-regex-not-initialized](44-cpp-std-regex-not-initialized) | pending | cpp: importing only classes from std/regex skips its init; a `Regex` segfaults |
| [45-lua-long-list-literal](45-lua-long-list-literal) | pending | lua: a 250-element list literal does not load |
| [46-rust-test-hides-cargo-errors](46-rust-test-hides-cargo-errors) | pending | `temper test -b rust` says "0 of N" and exits 0 when the crate does not compile |
| [47-java-test-stale-surefire-report](47-java-test-stale-surefire-report) | pending | `temper test -b java` reports the previous run when javac fails |
| [48-missing-tool-npe](48-missing-tool-npe) | pending | a missing `lua` or `cargo` gives a NullPointerException |
| [49-float-division-by-zero](49-float-division-by-zero) | [#373](https://github.com/temperlang/temper/issues/373), comment pending | Float64 division by zero: which backends bubble (comment) |
| [50-constant-closure-not-expanded](50-constant-closure-not-expanded) | [#510](https://github.com/temperlang/temper/issues/510), comment pending | two more shapes that #513 fixes (comment) |
| [51-void-bubble-loses-field-write](51-void-bubble-loses-field-write) | [#536](https://github.com/temperlang/temper/issues/536), comment pending | on js the dangling `return__N` loses a field write (comment) |
| [52-py-loop-let-capture](52-py-loop-let-capture) | [#264](https://github.com/temperlang/temper/issues/264), comment pending | py late-binds a `let` in a loop and a `for of` variable (comment) |
| [53-test-failed-shown-once](53-test-failed-shown-once) | [#505](https://github.com/temperlang/temper/issues/505), comment pending | the cause of one "Test failed" line per run (comment) |

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
