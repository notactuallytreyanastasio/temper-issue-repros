# std/net: a 404 response is a status on js and java, a broken promise on rust, and a hang on py

`NetRequest.send()` does four different things when the server answers 404.

```temper
let { NetRequest } = import("std/net");

console.log("before");
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  do {
    let r = await new NetRequest("http://127.0.0.1:18766/missing").send();
    console.log("status ${r.status.toString()}");
  } orelse console.log("broken promise");
  console.log("after");
}
```

with `python3 -m http.server 18766 --bind 127.0.0.1` running in
[`www`](www), which has `present.txt` and no `missing` (`curl` gets 404 from it).

| Backend | Output |
|---|---|
| js | `before`, `status 404`, `after` |
| java | `before`, `status 404`, `after` |
| rust | `before`, `broken promise`, `after` |
| py | under `temper run`, nothing; it had not returned after 120 seconds |
| cpp | `before`, then `libc++abi: terminating`, `Run failed` |

Run outside `temper run`, the py output shows why: the request throws on
the worker thread, the promise is never settled, and the program waits for
it forever.

```
before
Traceback (most recent call last):
  File ".../temper_core/__init__.py", line 1132, in _step_async_coro
    yielded = generator.send(cast(_sacT, result))
  File ".../temper_core/__init__.py", line 1274, in do_fetch
    with urllib.request.urlopen(request) as response:
  ...
urllib.error.HTTPError: HTTP Error 404: File not found
```

(then no further output until killed).

Two more libraries:

[`get-present`](get-present/src/main.temper.md) requests a file the server
has. js, py, java and rust print `before`, `status 200`, `after`. cpp ends
the same way as for the 404 (`libc++abi: terminating`), so cpp fails before
the status matters, and is not part of this report beyond that line.

[`get-refused`](get-refused/src/main.temper.md) requests port 1, where
nothing listens. js, java and rust print `broken promise`; py hangs as
for the 404. So the py hang is any error from `urlopen`, and the 404 is
the common way to reach it.

```sh
(cd 31-net-404-per-backend/www && python3 -m http.server 18766 --bind 127.0.0.1) &
./repro.sh 31-net-404-per-backend/get-missing js
./repro.sh 31-net-404-per-backend/get-missing rust
./repro.sh 31-net-404-per-backend/get-missing py      # does not return
./repro.sh 31-net-404-per-backend/get-present py
./repro.sh 31-net-404-per-backend/get-refused py      # does not return
```

java was run with JDK 27 first on `PATH` because of #525.

## Expected

One behavior on every backend. The doc comment on `send` says "Backends may
or may not support all request features in which case, send should return
a broken promise", and `NetResponse.status` is documented as the HTTP status
code, so a 404 resolving with `status` 404, as on js and java, reads as the
intent. Whatever the choice, py should settle the promise rather than hang.

## Notes

From reading the code at ffba652a.

py: `std_net_send` calls `urllib.request.urlopen` in `do_fetch` with no
handler around it
(`be-py/src/commonMain/resources/lang/temper/be/py/temper-core/temper_core/__init__.py:1253-1287`,
the call at `:1274`). `urlopen` raises `HTTPError` for 4xx and 5xx, and
`URLError` when it cannot connect, so `net_response_future` is never
completed or broken. The `try` that is there covers only reading the body.
`HTTPError` is itself a response object with `.status`, `.headers` and
`.read()`, so catching it could resolve with the status as js and java do.

rust: `make_request` uses `ureq` 3.1.2, which by default returns
`Err(StatusCode(404))` for 4xx and 5xx, and `send` breaks the promise on any
`Err` (`be-rust/src/commonMain/resources/lang/temper/be/rust/std/net/support.rs:46-60`).
Setting ureq's `http_status_as_error(false)` would give the js and java
behavior; not tried.

js uses `fetch` and java `HttpClient`, which both return the response for
any status.

Not checked: csharp (no `dotnet`). lua stops before the request with
`bad connected key: async`.
