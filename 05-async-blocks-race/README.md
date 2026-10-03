# Async blocks run in parallel on py and java, and lose updates to shared state

Three `async` blocks each add 1 to the same field 3,000,000 times. The
interpreter, js and rust run the blocks one after another, and the field ends
at 9,000,000. py and java run them on parallel threads, and updates are lost
in code that has no `await` in it:

```
js      top start | top end | A start | A done n=3000000 | B start | B done n=6000000 | C start | C done n=9000000
rust    top start | top end | A start | A done n=3000000 | B start | B done n=6000000 | C start | C done n=9000000
py      top start | A start | B start | C start | top end | A done n=5757391 | B done n=6014879 | C done n=6148940
java    top start | top end | A start | C start | B start | C done n=3226547 | A done n=3226547 | B done n=2465818
```

Each block prints `n` when its own loop ends, so on one thread the last line
reads 9,000,000. On py it ends near 6,000,000, on java near 3,000,000, and
the numbers change from run to run. On java a block can even report a lower
value than one printed before it, since the threads read and write the field
with no synchronization.

## Source

[`counter/src/main.temper.md`](counter/src/main.temper.md):

```temper
class Counter {
  public var n: Int = 0;
  public bump(tag: String, times: Int): Void {
    for (var i = 0; i < times; ++i) {
      let before = n;
      n = before + 1;
    }
    console.log("${tag} done n=${n.toString()}");
  }
}

let c = new Counter();
console.log("top start");
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("A start");
  c.bump("A", 3000000);
}
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("B start");
  c.bump("B", 3000000);
}
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  console.log("C start");
  c.bump("C", 3000000);
}
console.log("top end");
```

```sh
./repro.sh 05-async-blocks-race/counter js
./repro.sh 05-async-blocks-race/counter py
./05-async-blocks-race/run-java.sh
```

`run-java.sh` builds with the CLI and compiles with `javac`, because
`temper run -b java` on `e9ff0d25` stops on the JDK version string
`21.0.12.1` (`SemVerParseError` from `Java17Specifics.checkVersion`).

## Where each backend schedules async blocks

| Backend | How a block is started | Result here |
|---|---|---|
| interpreter | FIFO ready queue, `fundamentals/.../value/Promises.kt:31,109` | one at a time, by reading the code |
| js | `setTimeout`, `be-js/.../temper-core/async.js:7` | one at a time, 9,000,000 |
| rust | default `SingleThreadAsyncRunner`, `be-rust/.../temper-core/src/lib.rs:349` | one at a time, 9,000,000 |
| py | `ThreadPoolExecutor().submit`, `be-py/.../temper_core/__init__.py:1046,1195` | parallel, about 6,000,000 |
| java | `ForkJoinPool.commonPool().execute`, `be-java/.../temper/core/Core.java:1730` | parallel, about 3,000,000 |
| csharp | `Task.Run` and `ContinueWith`, `be-csharp/.../temper-core/Async.cs:60,115` | parallel by reading the code; not run here (no `dotnet`) |

The language has no threads, locks or atomics, and its docs describe
`async` only as running a block "out of band". Code written for it has no
way to protect shared state, so it behaves like the interpreter on one
backend and loses data on another. The order differs too: on py the three
blocks start before `top end` prints.

## Expected

One answer on every backend. The interpreter's behaviour, one block running
at a time and switching only at `await`, is what js and rust already do. On py and java that could be a
single worker thread or an event loop in place of a pool; on csharp, a
single-threaded scheduler. Rust's runner is already pluggable, so a host
that installs a multi-threaded one would need the same rule spelled out.
