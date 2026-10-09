# `temper run -b js` throws NoSuchElementException when the library it is asked to run is not configured: a mistyped `--library`, or a config file that does not parse

[`bad-config`](bad-config/src/config.temper.md) has a config file that
does not parse:

```temper
export let name = ;
```

On js the CLI prints the parse errors, then dies with an uncaught Kotlin
exception:

```
$ temper run --library bad-config -b js
[-work/src/config.temper.md:3+11-21]@P: Operator Eq expects at least 2 operands but got 1
[-work/src/config.temper.md:3+4-21]@P: Expected a TopLevel here
Exception in thread "main" java.util.NoSuchElementException: Key bad-config is missing in the map.
	at kotlin.collections.MapsKt__MapWithDefaultKt.getOrImplicitDefaultNullable(MapWithDefault.kt:24)
	at kotlin.collections.MapsKt__MapsKt.getValue(Maps.kt:370)
	at lang.temper.be.js.RunJsKt.runJsBestEffort(RunJs.kt:69)
	at lang.temper.be.js.NodeSpecifics.runBestEffort(NodeSpecifics.kt:44)
	at lang.temper.be.cli.RunnerSpecifics.runBestEffort(Specifics.kt:81)
```

The same happens with a library that builds, when `--library` names one
that does not exist:

```
$ temper run --library no-such-library -b js -w 58-js-run-missing-library-crash/good-config
Exception in thread "main" java.util.NoSuchElementException: Key no-such-library is missing in the map.
```

Both exit 1. The other backends report a `CliFailure` and `Run failed`
for both commands:

| Backend | message |
|---|---|
| py | `Missing py library name for RunLibraryRequest(libraryName=bad-config, taskName=run)` |
| lua | `No lua main path for bad-config` |
| java | `No main class for bad-config` |

```sh
./repro.sh 58-js-run-missing-library-crash/bad-config js
./repro.sh 58-js-run-missing-library-crash/bad-config py
"$TEMPER" run --library no-such-library -b js -w 58-js-run-missing-library-crash/good-config
./repro.sh 58-js-run-missing-library-crash/good-config js
```

## Expected

A `Run failed` naming the library, as on the other backends, and no Kotlin
stack trace.

## Notes

`runJsBestEffort` looks the library up with `getValue` before it checks
anything (`be-js/src/commonMain/kotlin/lang/temper/be/js/RunJs.kt:66-74`):

```kotlin
is RunLibraryRequest -> {
    mainLibraryConfig = dependencies.libraryConfigurations
        .byLibraryName.getValue(request.libraryName)
    val jsLibraryName = dependencies.metadata[request.libraryName, JsMetadataKey.JsLibraryName]
        ?: return listOf(
            ToolchainResult(result = RFailure(CliFailure("No JS library name for $request"))),
        )
```

The metadata lookup below it already returns a `CliFailure` for a library
the build does not know, but the `getValue` throws first. py does only the
metadata lookup (`be-py/src/commonMain/kotlin/lang/temper/be/py/RunPython.kt:72-76`).
`mainLibraryConfig` is only read for its `libraryName`
(`RunJs.kt:145`, `:243`), so a plain `get` is enough.
