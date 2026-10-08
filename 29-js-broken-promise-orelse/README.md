# js: a promise broken before its async block awaits it kills node with UnhandledPromiseRejection, though the `await` has an `orelse`

```temper
let b = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let v = await b.promise orelse -1;
  console.log("got ${v}");
}
b.breakPromise();
```

js prints nothing from the program and exits 1:

```
node:internal/process/promises:392
      new UnhandledPromiseRejection(reason);
      ^

UnhandledPromiseRejection: This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). The promise rejected with the reason "undefined".
  code: 'ERR_UNHANDLED_REJECTION'
}

Node.js v24.19.0
Run failed
```

py, java, rust and the interpreter print `got -1`. cpp prints nothing, which
is #520 (top-level code settles the promise the block awaits).

[`break-after-await`](break-after-await/src/main.temper.md) is the control:
the promise is broken from a second `async` block, after the first one has
reached its `await`. That prints `got -1` on js, py, java, rust and cpp.

```sh
./repro.sh 29-js-broken-promise-orelse/await-broken-promise js
./repro.sh 29-js-broken-promise-orelse/await-broken-promise py
./repro.sh 29-js-broken-promise-orelse/break-after-await js
```

## Expected

`got -1` on js, as on the other backends.

## Notes

From reading `be-js/src/commonMain/resources/lang/temper/be/js/temper-core/async.js`
at ffba652a and the generated module:

```js
runAsync(fn);
b.breakPromise();
```

`runAsync` starts the generator in a `setTimeout` (`async.js:7`), so the
block has not run when `breakPromise` calls the native `reject`
(`async.js:66`). The handler that would route the rejection into the
generator's `catch` is attached by `doAwait` with `p.then(..., ...)`
(`async.js:26`), and only once the generator reaches the `await`. Node checks
for unhandled rejections when the microtask queue drains, which is before
the timer fires, and its default mode (`--unhandled-rejections=throw`)
ends the process.

`complete()` before the `await` does not have this problem, since a
fulfilled promise with no handler is not an error. That is why only
`breakPromise` shows it.

One way out, not tried: have `PromiseBuilder`'s constructor attach a no-op
rejection handler to its promise (`this.promise.catch(() => {})`), which
marks it handled without changing what later `then` calls see.

The larger program where this was found breaks a promise from inside one
async block while the block that awaits it has not started yet (its first
line, `y waiting`, never prints). js stops there with the same error, at
ffba652a too.
