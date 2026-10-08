# `items ?? []` with `items: List<String>?` is typed `List<AnyValue>`, and the java, rust and cpp output does not compile

```temper
export let count(items: List<String>?): Int {
  let xs = items ?? [];
  xs.length
}

console.log(count(["a", "b"]).toString());
console.log(count(null).toString());
```

The frontend accepts this with no diagnostic. It gives `xs` the type
`List<AnyValue>`, and each typed backend declares it that way and then
assigns a `List<String>` to it.

java:

```java
    public static int count(@Nullable List<String> items__1) {
        List<Object> xs__3;
        if (items__1 == null) {
            xs__3 = List.of();
        } else {
            xs__3 = items__1;
        }
        return xs__3.size();
    }
```

```
$ ./repro.sh 25-coalesce-empty-list-any-value/coalesce-empty-list java
[ERROR] .../CoalesceEmptyListGlobal.java:[16,21] incompatible types: java.util.List<java.lang.String> cannot be converted to java.util.List<java.lang.Object>
```

rust:

```
error[E0308]: mismatched types
  --> src/mod.rs:20:17
   |
16 |     let xs__3: temper_core::List<temper_core::AnyValue>;
   |                ---------------------------------------- expected due to this type
...
20 |         xs__3 = items__1.clone().unwrap();
   |                 ^^^^^^^^^^^^^^^^^^^^^^^^^ expected `Arc<Vec<AnyValue>>`, found `Arc<Vec<Arc<String>>>`
```

cpp:

```
init.cpp:12:14: error: no matching function for call to 'upcast'
   12 |         xs = temper::core::List::upcast<std::shared_ptr<temper::core::AnyValueBase>>(temper::core::not_null(items));
```

py writes the same type, `xs_3: 'Sequence4[Any6]'`, which does not matter
at run time. js, py and lua print

```
2
0
```

With the type written out, `let xs: List<String> = items ?? [];`
([`annotated`](annotated/src/main.temper.md)), all six backends I ran (js,
py, lua, java, rust, cpp) print `2` and `0`. A function that returns
`items ?? []` directly, with a declared `List<String>` return type, runs on
java and rust.

## Expected

`xs` typed `List<String>`, the type of the left side, which is the only
type the empty list can take here. Failing that, a frontend diagnostic
asking for an annotation, rather than output that javac, rustc and g++
reject.

## Notes

This looks like the same weakness as #246 (`new Map([])` in a default
parameter is inferred from `List<AnyValue>`), but there the frontend
reports an error, and here it reports nothing and the failure only shows
when the backend's compiler runs. I did not trace where the typer joins
the two branches. csharp was not run (no dotnet here).
