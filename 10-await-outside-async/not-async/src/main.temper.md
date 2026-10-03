# await in a function and a method that are not async

`waitFn` and `Box.waitFor` each `await` a promise. Neither is an `async`
block or extends `GeneratorFn`. The `async` block at the end calls both.

    export let waitFn(p: Promise<Int>): Int {
      await p orelse -1
    }

    export class Box {
      public var v: Int = 0;
      public waitFor(p: Promise<Int>): Void {
        v = await p orelse -1;
      }
    }

    let b = new PromiseBuilder<Int>();
    async { (): GeneratorResult<Empty> extends GeneratorFn =>
      let box = new Box();
      box.waitFor(b.promise);
      console.log("method ${box.v.toString()}");
      console.log("function ${waitFn(b.promise).toString()}");
    }
    b.complete(3);
