# `temper test -b java` reports the previous run's surefire results, and exits 0, when javac fails on the new code

When the Java for a library stops compiling, `temper test -b java` reads
the surefire report that the last successful run left in `temper.out`,
reports those results, and prints nothing about javac. If that old report
was all passes, it exits 0.

```
$ temper test -b java   # step 1
Tests passed: 1 of 1
exit 0

$ temper test -b java   # step 2, same temper.out
Tests passed: 1 of 2 (1 not run)
exit 0

test cases in the surefire report:
<testcase name="onePasses"

$ temper test -b java   # step 2, temper.out deleted
[ERROR] .../temper.out/java/stale-report/src/main/java/stale_report/Counter.java:[10,32] cannot find symbol
## exception.msg: /opt/homebrew/bin/mvn failed: exit code = 1
Test failed
Tests passed: 0 of 2 (2 not run)
exit 1
```

The second run's "1 passed" is step 1's test, read from step 1's report;
step 2's code never ran. The javac error is only in
`temper.out/java/maven.log`. The third run, on the same source with no old
report, shows the failure and exits 1.

In an earlier version of this sequence, step 1 also had a failing test
("two fails on purpose"), and the second run printed
`Test failed (java): two fails - two fails on purpose` and
"Tests passed: 1 of 3 (1 not run)" from step 1's report, for code that had
not compiled.

## Source

[`stale-report/src/main.temper.md`](stale-report/src/main.temper.md) is
step 1:

```temper
test("one passes") { test =>
  assert(1 + 1 == 2) { "arithmetic" }
}
```

[`step2.temper.md`](step2.temper.md) adds a class whose Java javac rejects
(the recursive local function from
[#535](https://github.com/temperlang/temper/issues/535); any javac error
will do) and a second test:

```temper
export class Counter(public n: Int) {
  public sumTo(): Int {
    let go(i: Int): Int {
      if (i <= 0) { 0 } else { n + go(i - 1) }
    }
    go(3)
  }
}

test("two fails") { test =>
  assert(new Counter(1).sumTo() == 4) { "sumTo is 3, not 4" }
}
```

`repro.sh` deletes `temper.out` before each run, so it cannot show this.
[`run-sequence.sh`](run-sequence.sh) copies the library to a temporary
directory and runs the three steps above:

```sh
TEMPER=/path/to/temper ./47-java-test-stale-surefire-report/run-sequence.sh
```

## Expected

The second run reports what the third does: the maven failure, exit 1, and
no test results from an earlier build.

## Notes

`RunAsTest` runs `mvn test` and then calls `withTestResult` for each
library (`be-java/src/commonMain/kotlin/lang/temper/be/java/RunJava.kt:190-207`).
`withTestResult` reads every `*.xml` under `target/surefire-reports` and, if
there are any, attaches them to the result as junit XML whether or not maven
succeeded (`RunJava.kt:271-279`). Nothing deletes old reports first, and a
compile failure stops maven before surefire writes new ones. `tallyResults`
prints a failed command only when there is no junit XML
(`tooling/src/commonMain/kotlin/lang/temper/tooling/buildrun/TestTally.kt:131-139`),
so the maven failure is dropped and the old results are counted.

I checked this by building the CLI at `ffba652a` with the report files
deleted before `doRunJava` in `RunAsTest`. With that, the second run prints
the maven failure with the javac error, "Tests passed: 0 of 2 (2 not run)",
and exits 1. That was a probe; deleting the reports, or ignoring them when
maven fails before the test phase, are both possible fixes, and I did not
check which fits the multi-library case at `RunJava.kt:199-206`.

I ran it with JDK 27 first on `PATH` because of
[#525](https://github.com/temperlang/temper/issues/525).
