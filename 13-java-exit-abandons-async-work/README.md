# Java's generated main exits after 10 seconds while an async block is still running, with exit code 0

The `main` that be-java generates waits for async work with
`ForkJoinPool.commonPool().awaitQuiescence(10L, TimeUnit.SECONDS)` and then
returns. An `async` block that is still running at that point is dropped:
the process exits 0, nothing is printed about it, and the block's remaining
output never appears. js and py run the same block to the end.

## Source

[`long-block/src/main.temper.md`](long-block/src/main.temper.md):

```temper
let rounds = 40;
console.log("main: start");
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("block: start");
  var x = 1;
  for (var r = 0; r < rounds; ++r) {
    for (var i = 0; i < 100000000; ++i) {
      x = (x * 31 + i) % 1000003;
    }
  }
  console.log("block: done x=${x.toString()}");
}
console.log("main: end");
```

## Commands and output

```
$ s=$(date +%s); ./repro.sh 13-java-exit-abandons-async-work/long-block js; echo "exit=$? secs=$(( $(date +%s)-s ))"
main: start
main: end
block: start
block: done x=625200

exit=0 secs=37

$ s=$(date +%s); ./repro.sh 13-java-exit-abandons-async-work/long-block py; echo "exit=$? secs=$(( $(date +%s)-s ))"
main: start
block: start
main: end
block: done x=625200

exit=0 secs=785

$ ./13-java-exit-abandons-async-work/run-java.sh long-block
main: start
main: end
block: start
exit=0 seconds=10
```

The js and py times include the CLI's build. `run-java.sh` times only the
`java` process. Three java runs gave the same output and the same 10
seconds.

The block needs about 15 seconds on java. Running the same compiled classes
from a scratch `main` that calls `awaitQuiescence(1L, TimeUnit.HOURS)` in
place of `Core.waitUntilTasksComplete()` prints `block: done x=625200` and
takes 15.35 s of wall time. With `rounds = 8` the generated `main` finishes
the block in 3.1 s and prints `done`, so the loss depends only on how long
the block runs.

`run-java.sh` builds with the CLI and runs `javac` and `java` by hand,
because `temper run -b java` on `e9ff0d25` stops on the JDK version string
`21.0.12.1` ([14-java-four-part-jdk-version](../14-java-four-part-jdk-version)).

## Expected

`main` waits until every block has finished, as js and py do, or, if a
limit stays, reports that it gave up and exits nonzero. A silent exit 0
with missing output reads as success in a script or CI job.

## Notes

Checked against temperlang/temper `e9ff0d25`. By reading the code:

`be-java/src/commonMain/resources/lang/temper/be/java/temper-core/src/main/java/temper/core/Core.java:1741-1747`:

```java
public static void waitUntilTasksComplete() {
    ForkJoinPool commonPool = ForkJoinPool.commonPool();
    // This timeout is sufficient for functional tests.
    // If a long running main method needs more time, it should
    // negotiate promises for termination with the tasks it spawns.
    commonPool.awaitQuiescence(10L, TimeUnit.SECONDS);
}
```

`awaitQuiescence` returns `false` when it times out, and the return value
is ignored. Blocks run on the common pool (`Core.java:1730`), whose threads
are daemon threads, so the JVM exits under them. `JavaTranslator.kt:300` and
`:352` emit the call to `waitUntilTasksComplete` in the generated `main`.
The comment's advice, to negotiate promises with the tasks, assumes a
hand-written `main`. Here `main` is generated, and I found no way for
Temper source to make it wait on a promise.

py waits with no limit: `await_safe_to_exit` in
`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:1198-1203`
calls `_all_resolved.wait()`.

A second library, [`never-completed`](never-completed/src/main.temper.md),
has a block that awaits a promise nobody completes. There the three backends
disagree in a different way, and java does not wait 10 seconds:

```
$ ./repro.sh 13-java-exit-abandons-async-work/never-completed js; echo "exit=$?"
main: start
main: end
block: awaiting
exit=0

$ ./13-java-exit-abandons-async-work/run-java.sh never-completed
main: start
main: end
block: awaiting
exit=0 seconds=0
```

js took 1.97 s including the build. The suspended block is not a pool task, so `awaitQuiescence` returns at
once. java matches js here. py never exits: the generated program, run
directly with `python3 -u top.py` under a 30 second alarm, printed
`main: start`, `block: awaiting`, `main: end` and was killed by the alarm
(exit 142). Through `temper run -b py` it printed nothing before the kill,
and killing the CLI left the `python -m top` child running.

Related upstream: [#144](https://github.com/temperlang/temper/issues/144)
("Adapt `await` to backends"), where the missing wait in java's `main` was
first reported, and [#516](https://github.com/temperlang/temper/issues/516),
which shows the same pool running blocks in parallel. No issue or PR found
for the timeout (searched issues and PRs for `awaitQuiescence`,
`waitUntilTasksComplete`, `async java`, `exit`, `timeout`, `ForkJoinPool`).
[#133](https://github.com/temperlang/temper/issues/133) ("Java sometimes
misses output") is about generated files missing from the build output, not
about program output.

Not checked: csharp and rust, which were not run here.
