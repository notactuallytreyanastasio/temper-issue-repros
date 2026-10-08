# A GET that the server answers with 404

Start `python3 -m http.server 18766 --bind 127.0.0.1` first.

    let { NetRequest } = import("std/net");

    console.log("before");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      do {
        let r = await new NetRequest("http://127.0.0.1:18766/missing").send();
        console.log("status ${r.status.toString()}");
      } orelse console.log("broken promise");
      console.log("after");
    }
