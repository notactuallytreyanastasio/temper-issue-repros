# java: a function type with `throws Bubble` and a non-primitive return becomes `Function<String, Result>`, and `Result` does not exist

```temper
export let applyAll<T>(xs: List<String>, f: fn (String): T throws Bubble): List<T> throws Bubble {
  let out = new ListBuilder<T>();
  for (let x of xs) { out.add(f(x)); }
  out.toList()
}

export let applyOne(x: String, f: fn (String): String throws Bubble): String throws Bubble {
  f(x)
}

let nums = applyAll(["1", "22"]) { (s: String): Int throws Bubble => s.toInt32() } orelse panic();
console.log(nums.join(",") { (n) => n.toString() });
console.log(applyOne("a") { (s: String): String throws Bubble => s } orelse panic());
```

The java backend gives both parameters a type argument named `Result`:

```java
    public static<T__0> List<T__0> applyAll(List<String> xs__4, Function<String, Result> f__5) {
    ...
    public static String applyOne(String x__9, Function<String, Result> f__10) {
```

and javac rejects it (from `temper.out/java/maven.log`):

```
$ ./repro.sh 39-java-throwing-fn-type-result/throwing-callback java
[ERROR] .../ThrowingCallbackGlobal.java:[14,82] cannot find symbol
  symbol:   class Result
  location: class throwing_callback.ThrowingCallbackGlobal
[ERROR] .../ThrowingCallbackGlobal.java:[28,65] cannot find symbol
  symbol:   class Result
  location: class throwing_callback.ThrowingCallbackGlobal
```

js and py run it:

```
$ ./repro.sh 39-java-throwing-fn-type-result/throwing-callback js
1,22
a
$ ./repro.sh 39-java-throwing-fn-type-result/throwing-callback py
1,22
a
```

The parameter type is what matters, not generics: `applyOne` has no type
parameter and fails the same way. In a separate build, without
`throws Bubble` the same shape gives `Function<String, T__0>`, and
`fn (T): Int throws Bubble` gives `ToIntFunction<T__2>`. Both are fine;
only a boxed return type with `throws Bubble` produces `Result`.
`fn (): T throws Bubble` gives `Supplier<Result>`.

## Expected

`Function<String, T__0>` and `Function<String, String>`, as the backend
already writes when the type has no `throws Bubble`, and output `1,22` and
`a`.

## Notes

From reading `be-java/src/commonMain/kotlin/lang/temper/be/java/JavaTypes.kt`
at upstream main: `fromTmpL` for a `TmpL.FunctionType` computes the
signature's return type with `toFrontend(type.returnType.ot)` (line 333).
For a union that includes `BubbleType`, `toFrontend` wraps the principal
type in `Result<principal, Bubble>` (line 298). `samJavaType` then adds that
return type as a type argument with `JavaTypeArg.fromStatic` (line 391),
which prints the bare name `Result`. `fromTmpL` itself skips `BubbleType`
in a union (the `TmpL.TypeUnion` branch below), which is why a plain
`String throws Bubble` return type on a method is translated correctly. I
did not trace further than that.
