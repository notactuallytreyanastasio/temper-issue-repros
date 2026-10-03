# rust: a method call on a field holds the object's read lock, and a write back to the object deadlocks

On the rust backend, `peer.pong(this)` inside a method of `Ping` compiles to
`self.0.read().unwrap().peer.pong(self.clone())`. The read guard on `Ping`
lives until the end of that statement, so when `pong` assigns to a field of
the same `Ping`, the write lock waits on a guard its own thread holds. The
program hangs on one thread with no async code and no host threads. js and
py print `ping returned 1`.

## Source

[`held-guard/src/main.temper.md`](held-guard/src/main.temper.md):

```temper
class Pong {
  public pong(a: Ping): Void { a.n += 1; }
}

class Ping(public peer: Pong) {
  public var n: Int = 0;
  public ping(): Int { peer.pong(this); n }
}

let p = new Ping(new Pong());
console.log("before ping");
console.log("ping returned ${p.ping()}");
```

```sh
./repro.sh 06-rust-lock-held-across-call/held-guard js
./repro.sh 06-rust-lock-held-across-call/held-guard py
perl -e 'alarm 60; exec @ARGV' ./repro.sh 06-rust-lock-held-across-call/held-guard rust
```

## Output

js and py:

```
before ping
ping returned 1

exit code: 0
```

rust, stopped by the 60 second alarm (exit code 142 is SIGALRM). The CLI
prints nothing, not even `before ping`:

```
exit code: 142
```

The binary the CLI built, run on its own, prints the first line and then
waits without using CPU:

```
$ time perl -e 'alarm 10; exec @ARGV' held-guard/temper.out/rust/held-guard/target/debug/held-guard
before ping
perl -e 'alarm 10; exec @ARGV'   0.00s user 0.00s system 0% cpu 10.013 total
```

The generated method, `temper.out/rust/held-guard/src/mod.rs`:

```rust
impl Ping {
    pub fn ping(& self) -> i32 {
        self.0.read().unwrap().peer.pong(self.clone());
        return self.0.read().unwrap().n;
    }
```

`pong` calls `a.set_n(...)`, which is `self.0.write().unwrap().n = ...` on
the same `Arc<RwLock<PingStruct>>`.

## Expected

`ping returned 1` on rust, as on js and py. Editing the generated line by
hand to `let t = self.0.read().unwrap().peer.clone(); t.pong(self.clone());`
releases the guard before `pong` runs, and the rebuilt binary prints
`before ping` and `ping returned 1`.

## Second case: two reads in one expression, under host threads

The same guard lifetime deadlocks across threads when one expression reads
two fields. [`two-reads/src/main.temper.md`](two-reads/src/main.temper.md):

```temper
export class Gauge {
  public var inside: Int = 0;
  public var maxInside: Int = 0;
  public bump(): Void {
    inside += 1;
    if (inside > maxInside) { maxInside = inside; }
    inside -= 1;
  }
}
```

The comparison compiles to

```rust
if self.0.read().unwrap().inside > self.0.read().unwrap().max_inside {
```

which takes a second read lock while holding the first. If another thread
asks for the write lock between the two, the second read waits behind that
writer, and the writer waits for the first read. [`run-threads.sh`](run-threads.sh)
builds the case and runs [`host/main.rs`](host/main.rs), which calls `bump`
from 8 threads. Three runs:

```
./06-rust-lock-held-across-call/run-threads.sh: line 23: 27018 Alarm clock: 14         perl -e 'alarm 20; exec @ARGV' "$host/target/release/host"
exit code: 142
./06-rust-lock-held-across-call/run-threads.sh: line 23: 27424 Alarm clock: 14         perl -e 'alarm 20; exec @ARGV' "$host/target/release/host"
exit code: 142
./06-rust-lock-held-across-call/run-threads.sh: line 23: 27569 Alarm clock: 14         perl -e 'alarm 20; exec @ARGV' "$host/target/release/host"
exit code: 142
```

`sample` on the hung process shows every worker thread in
`two_reads::mod::Gauge::bump`, inside
`std::sys::sync::rwlock::queue::RwLock::lock_contended`. With 1 thread the
harness finishes (`done: inside=0 maxInside=1`); with 2 threads it hung in
3 of 3 runs. Writing the comparison as
`let i = inside; let m = maxInside; if (i > m) { maxInside = i; }` puts each
read in its own statement, and the 8 thread harness then finishes in 5 of 5
runs.

This case needs host threads, which Temper code cannot start by itself. The
generated types are `Arc<RwLock<...>>` and `Clone`, so a Rust host can share
them across threads as written.

## Notes

Checked on `e9ff0d25` with rustc 1.96.0, macOS 26.2 on arm64. Not run on
Linux or Windows, where `std::sync::RwLock` uses a different implementation;
whether the single thread case panics there instead of hanging is not
verified.

Where the guard comes from, by reading the code in
`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustTranslator.kt`:

- `translatePropertyReference`, lines 2791 to 2825, turns a read of an
  internal property into `self.0.read().unwrap().<field>` (the lock call is
  at line 2812) and returns the place expression without copying out of it.
- `translateCallable`, line 1859, translates a method call's subject with
  `avoidClone = true` ("Method calls typically use refs for self, so no
  need to clone"), so the call borrows through the guard and the guard
  lives for the whole call.

The second case has the same cause: each operand of `>` is its own
`.read().unwrap()` temporary, and Rust drops temporaries at the end of the
enclosing statement, here the whole `if` condition.

In the threaded control run above, `inside` ended at values such as `-199`
and `10` instead of `0`, because `inside += 1` is a read lock followed by a
separate write lock. That is a separate question about what the rust
backend promises for shared objects, and this case does not depend on it.
