# A GET that the server cannot connect to (port 1)

    let { NetRequest } = import("std/net");

    console.log("before");
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      do {
        let r = await new NetRequest("http://127.0.0.1:1/refused").send();
        console.log("status ${r.status.toString()}");
      } orelse console.log("broken promise");
      console.log("after");
    }
