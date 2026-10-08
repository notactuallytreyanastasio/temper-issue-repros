# A `static get` or `static set` crashes the compiler with `NotImplementedError` instead of reporting a diagnostic

```temper
export class C {
  public static get answer(): Int { 42 }
}
```

`temper build` exits 1 with a Kotlin stack trace and no source position:

```
Exception in thread "main" kotlin.NotImplementedError: An operation is not implemented: static computed property declaration
	at lang.temper.frontend.disambiguate.TypeDisambiguateMacroKt.typeDisambiguateMacro(TypeDisambiguateMacro.kt:705)
	at lang.temper.frontend.TypeDefinitionMacro.invoke(TypeDefinitionMacro.kt:109)
	at lang.temper.interp.ForwardingFeatureMacro.invoke(ForwardingFeatureMacro.kt:56)
	...
	at lang.temper.tooling.buildrun.BuildKt.stageLibraries(Build.kt:270)
```

The crash is in the frontend, so every backend gives the same trace; it was
run with `-b js` and `-b py`. A static setter,
`public static set count(v: Int): Void { n = v; }`, gives the same message.
In `temper repl` the same class prints
`An operation is not implemented: static computed property declaration at TypeDisambiguateMacro.kt:705`.

```sh
./repro.sh 24-static-getter-crash/static-getter js
```

## Expected

Either static getters and setters work, or the compiler reports an error at
the declaration, with its position, saying they are not supported.

## Notes

`frontend/src/commonMain/kotlin/lang/temper/frontend/disambiguate/TypeDisambiguateMacro.kt:705`:

```kotlin
if (hasStaticAnnotation) { TODO("static computed property declaration") }
```

Instance getters (`get age()`) are documented in
`docs/for-users/temper-docs/docs/index.md:276`; static ones are not
mentioned in the docs that were searched. The js backend's grammar has a
`static get` form (`be-js/src/commonMain/kotlin/lang/temper/be/js/Js.kt:6171`),
so the output side may already support it; from reading.

Workaround: a static method, `public static answer(): Int { 42 }`.
