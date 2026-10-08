# cpp: calling a method named after a C++ keyword, such as `int` or `bool`, crashes the translator

The cpp backend declares the method under a fixed-up name, `int_`, and then
crashes when it translates a call to it:

```temper
export class B {
  public int(k: Int): Int { k + 1 }
}

let b = new B();
console.log(b.int(41).toString());
```

```
$ ./repro.sh 43-cpp-method-named-keyword/instance-method cpp
Exception in thread "main" java.lang.IllegalArgumentException: Failed requirement.
	at lang.temper.be.cpp.CppName.<init>(CppNames.kt:41)
	at lang.temper.be.cpp.CppName.<init>(CppNames.kt:33)
	at lang.temper.be.cpp.CppTranslator.translateCallable(CppTranslator.kt:931)
	at lang.temper.be.cpp.CppTranslator.translateCallExpression(CppTranslator.kt:1111)
	...
```

The CLI exits 1 with no diagnostic that names the method. A static method
crashes the same way at line 945
([`static-method`](static-method/src/main.temper.md), `B.bool(k)`).

js and py run both cases:

```
$ ./repro.sh 43-cpp-method-named-keyword/instance-method js
42
$ ./repro.sh 43-cpp-method-named-keyword/instance-method py
42
$ ./repro.sh 43-cpp-method-named-keyword/static-method js
true
$ ./repro.sh 43-cpp-method-named-keyword/static-method py
true
```

With the call removed, the class builds on cpp, and the header declares the
method as

```cpp
    int32_t int_(int32_t) const;
```

so only the call site is missing the rename. A call from inside the class
(`int(int(k))` in a sibling method) crashes the same way at line 931. I
tried these other method names with an instance call, and each crashes at the
same place: `bool`, `double`, `float`, `char`, `long`, `short`, `auto`,
`union`, `struct`, `template`, `operator`, `delete`, `register`,
`namespace`, `typename`, `volatile`. A top-level function named `int` and a
property named `int` (`b.int`) both build.

## Expected

The call translates to `b->int_(41)`, matching the declaration, and the
program prints `42`.

## Notes

`CppName`'s constructor (`be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppNames.kt:41`)
requires that the text is not in `cppKeywords`. The declaration side passes
the name through `fixName`, which appends `_` to a keyword
(`CppTranslator.kt:2350` and `:2429`). `translateCallable` builds the method
name with `CppName(fn.methodName.dotNameText)` and no `fixName`, in all four
branches of `TmpL.MethodReference`: lines 931 (instance), 941
(`ConnectedToTypeName`), 945 (`TemperTypeName`, the static case) and 953
(`SuperSubject`). Lines 941 and 953 are from reading; I did not build a
case that reaches them.
