# std/net `NetRequest.post` ignores its `mimeType` argument, so every backend sends its own default Content-Type

`post(content, mimeType)` in `std/net` assigns the field to itself instead
of storing `mimeType`
(`frontend/src/commonMain/resources/std/net/net.temper.md:20-24`):

```temper
public post(content: String, mimeType: String): Void {
  this.method = "POST";
  this.bodyContent = content;
  this.bodyMimeType = bodyMimeType;
}
```

Inside the method, `bodyMimeType` is the field, which is still `null`. The
generated code shows it:

```js
post(content_6, mimeType_7) {
  this.#method_2 = "POST";
  this.#bodyContent_3 = content_6;
  const t_8 = this.#bodyMimeType_4;
  this.#bodyMimeType_4 = t_8;
  return;
}
```

```python
this_0._body_content_19 = content_22
t_43: 'Union3[str2, None]' = this_0._body_mime_type_20
this_0._body_mime_type_20 = t_43
```

`sendRequest` then gets `null`, each backend's runtime skips the header,
and the HTTP library falls back to its own default. Posting a JSON body
with `"application/json"` to a server that echoes the request's
Content-Type:

```
js    {"contentType": "text/plain;charset=UTF-8", "body": "{\"x\":1}"}
py    {"contentType": "application/x-www-form-urlencoded", "body": "{\"x\":1}"}
java  {"contentType": "application/x-www-form-urlencoded", "body": "{\"x\":1}"}
rust  {"contentType": null, "body": "{\"x\":1}"}
```

The body arrives intact on all four. A server that reads the body by its
Content-Type sees a form post on py and java, plain text on js, and no
type on rust.

## Source

[`post-json/src/main.temper.md`](post-json/src/main.temper.md):

```temper
let { NetRequest } = import("std/net");

async { (): GeneratorResult<Empty> extends GeneratorFn =>
  do {
    let req = new NetRequest("http://127.0.0.1:18765/");
    req.post("{\"x\":1}", "application/json");
    let resp = await req.send();
    console.log((await resp.bodyContent) ?? "no body");
  } orelse console.log("send failed");
}
```

[`echo_server.py`](echo_server.py) listens on 127.0.0.1:18765 and answers
each POST with the Content-Type and body it received.

```sh
python3 22-net-post-content-type/echo_server.py &
./repro.sh 22-net-post-content-type/post-json js
./repro.sh 22-net-post-content-type/post-json py
./repro.sh 22-net-post-content-type/post-json java
./repro.sh 22-net-post-content-type/post-json rust
```

## Expected

`{"contentType": "application/json", ...}` on every backend.

## Fix

```diff
-        this.bodyMimeType = bodyMimeType;
+        this.bodyMimeType = mimeType;
```

With this change, built at `ffba652a`, all four backends send
`application/json`. The runtimes already set the header when they get a
value: `be-js/.../temper-core/net.js:12-13`,
`be-py/.../temper_core/__init__.py:1265-1266`,
`be-java/.../temper/core/net/Core.java:39-40`,
`be-rust/.../std/net/support.rs:75-76` (from reading; the four runs above
agree).

## Notes

The functional test `types/netresponse` posts `"application/json"` but only
checks that the response body starts with `{`
(`functional-test-suite/src/commonMain/resources/types/netresponse/netresponse.temper.md:13-24`),
so it passes either way. The frontend gives no warning for the
self-assignment or the unused parameter.

Not covered: cpp aborts on this program before printing anything
(`libc++abi: terminating`, exit 134), and lua stops at
`bad connected key: async`; neither was investigated. csharp was not run
(no `dotnet` here), though its runtime handles a non-null type the same way
(`be-csharp/.../std/Net/NetSupport.cs:76-79`, from reading).
