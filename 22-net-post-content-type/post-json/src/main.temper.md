# POST a JSON body with an application/json content type

    let { NetRequest } = import("std/net");

    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      do {
        let req = new NetRequest("http://127.0.0.1:18765/");
        req.post("{\"x\":1}", "application/json");
        let resp = await req.send();
        console.log((await resp.bodyContent) ?? "no body");
      } orelse console.log("send failed");
    }
