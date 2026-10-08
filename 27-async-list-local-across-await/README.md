# java, rust and cpp crash translating an async block that keeps a `List` local across an `await`

The build throws inside the backend's translator, with no source position:

```temper
let p = new PromiseBuilder<Int>();
async { (): GeneratorResult<Empty> extends GeneratorFn =>
  let xs = [1, 2];
  let x = await p.promise orelse -1;
  console.log("${x} ${xs.length}");
}
p.complete(3);
```

java:

```
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented.
	at lang.temper.be.java.JavaTranslator$ModuleScope.value(JavaTranslator.kt:2357)
	at lang.temper.be.java.JavaTranslator$ModuleScope.expr(JavaTranslator.kt:1798)
	at lang.temper.be.java.JavaTranslator$ModuleScope.block(JavaTranslator.kt:1440)
```

rust:

```
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented: []
	at lang.temper.be.rust.RustTranslator.translateValueReference(RustTranslator.kt:3420)
	at lang.temper.be.rust.RustTranslator.translateExpression$be_rust(RustTranslator.kt:2137)
	at lang.temper.be.rust.RustTranslator.translateModuleOrLocalDeclaration(RustTranslator.kt:2721)
```

cpp:

```
Exception in thread "main" java.lang.IllegalStateException: C++ backend cannot translate literal with tag List (type List)
	at lang.temper.be.cpp.CppTranslator.translateValueReference(CppTranslator.kt:1349)
```

js, py and the interpreter print `3 2`.

The list literal is not what matters.
[`list-from-call`](list-from-call/src/main.temper.md) gets the list from
`"a,b".split(",")` and fails the same way on java and rust. The
[`list-no-await`](list-no-await/src/main.temper.md) control has the literal
and no `await`; it prints `2` on java, rust, cpp, js and py.

```sh
./repro.sh 27-async-list-local-across-await/list-then-await java
./repro.sh 27-async-list-local-across-await/list-then-await rust
./repro.sh 27-async-list-local-across-await/list-then-await cpp
./repro.sh 27-async-list-local-across-await/list-from-call rust
./repro.sh 27-async-list-local-across-await/list-no-await rust
```

## Expected

`3 2` on every backend.

## Notes

From reading the code at ffba652a. A local that lives across an `await` is
hoisted out of the coroutine body and initialized to a zero value for its
type (`frontend/src/commonMain/kotlin/lang/temper/frontend/coroutine/CoroutineConverter.kt:767-782`,
the initializer at `:904`). The zero value for `List` is the constant
`Value(listOf(), TList)` (`fundamentals/src/commonMain/kotlin/lang/temper/value/ZeroValues.kt:43`).
No translator handles a constant list: java has `TList -> TODO()`
(`be-java/src/commonMain/kotlin/lang/temper/be/java/JavaTranslator.kt:2357`),
rust `TList -> TODO("$expression")` (`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustTranslator.kt:3420`),
and cpp raises the error above (`be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppTranslator.kt:1349`).
js and py translate the constant, which is why they run.

Two ways out, not tried here: drop the `List` entry from `ZeroValues` so a
hoisted `List` local takes the nullable path every other reference type
takes (null plus a not-null adjustment where it is read), or have each
translator emit an empty list for a constant empty `List`.

#245 reports that the csharp translator cannot translate `TList` either;
csharp was not run here (no `dotnet`). lua was not run: it has no
`PromiseBuilder` (`bad connected key: promisebuilder_constructor`).
