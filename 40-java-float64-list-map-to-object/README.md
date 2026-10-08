# java: `List<Float64>.map` to any object type does not compile, because `Core.listMapDoubleToObj` is declared to return `List<Boolean>`

```temper
export let names(xs: List<Float64>): List<String> {
  xs.map { (f): String => f.toString() }
}

let prices: List<Float64> = [0.25, 3.0];
let labels = prices.map { (f): String => "$${f.toString()}" };

console.log(names([1.5, 2.0]).join(",") { (s) => s });
console.log(labels.join(",") { (s) => s });
```

The java backend translates both `map` calls to `Core.listMapDoubleToObj`:

```java
        DoubleFunction<String> fn__15 = f__5 -> Core.float64ToString(f__5);
        return Core.listMapDoubleToObj(xs__3, fn__15);
    ...
        labels__2 = Core.listMapDoubleToObj(prices__1, FloatMapGlobal :: fn);
```

and javac rejects both (from `temper.out/java/maven.log`):

```
$ ./repro.sh 40-java-float64-list-map-to-object/float-map java
[ERROR] .../FloatMapGlobal.java:[15,47] incompatible types: java.util.function.DoubleFunction<java.lang.String> cannot be converted to java.util.function.DoubleFunction<java.lang.Boolean>
[ERROR] .../FloatMapGlobal.java:[29,56] incompatible types: bad return type in method reference
    java.lang.String cannot be converted to java.lang.Boolean
```

js and py run it:

```
$ ./repro.sh 40-java-float64-list-map-to-object/float-map js
1.5,2.0
$0.25,$3.0
$ ./repro.sh 40-java-float64-list-map-to-object/float-map py
1.5,2.0
$0.25,$3.0
```

## Expected

The same two lines on java.

## Notes

The helper in the java runtime is not generic, unlike its `Int` sibling
just above it
(`be-java/src/commonMain/resources/lang/temper/be/java/temper-core/src/main/java/temper/core/Core.java`):

```java
1064:    public static <F> List<F> listMapIntToObj(List<Integer> source, IntFunction<F> function) {
1079:    public static List<Boolean> listMapDoubleToObj(List<Double> source, DoubleFunction<Boolean> function) {
```

Line 1079 looks like a copy of the `...ToBool` shape. Declaring it as
`<F> List<F> listMapDoubleToObj(List<Double> source, DoubleFunction<F> function)`,
with `List<F> result` in the body, should fix this; I have not built Temper
with that change. Mapping a `List<Float64>` to `Boolean` would compile
today, but the translator picks `listMapDoubleToBool` for that, so the
`Boolean` signature serves no caller I found.
