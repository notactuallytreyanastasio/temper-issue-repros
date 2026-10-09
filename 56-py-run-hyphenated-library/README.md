# `temper run -b py` fails with ModuleNotFoundError for a library whose name has a dash, unless the build records a dependency from that library on another

A library named `hello-world` that only prints:

```temper
console.log("hello");
```

```
$ temper run --library hello-world -b py
...
    import hello_world as module
ModuleNotFoundError: No module named 'hello_world'
Run failed
```

js, java, lua, cpp and rust print `hello`. A library named `hello`, with
no dash, prints `hello` on py too.

The command the CLI runs shows why:

```
## Command: cd .../hello-world/temper.out/py; PYTHONIOENCODING=UTF-8 PYTHONPATH=.../temper.out/py/hello_world:.../temper.out/py/temper-core:.../temper.out/py/deps .../py_venv/bin/python -m top
```

The package is at `temper.out/py/hello-world/hello_world/__init__.py`, so
`temper.out/py/hello-world` has to be on `PYTHONPATH`. What is there is
`temper.out/py/hello_world`, which does not exist.

[`adds-one`](adds-one/src/main.temper.md) is the same program plus an
`Int` addition that is not folded away:

```temper
var x = 41;
x = x + 0;
console.log("hello");
console.log((x + 1).toString());
```

It prints `hello` and `42` on py, because its `PYTHONPATH` gains the right
directory by another route:

```
PYTHONPATH=.../py/adds_one:.../py/temper-core:.../py/adds-one:.../py/deps
```

So whether a library with a dash in its name runs on py depends on what its
code uses. `temper test -b py` is not affected; it runs from inside
`temper.out/py/<library>`.

```sh
./repro.sh 56-py-run-hyphenated-library/hello-world py
./repro.sh 56-py-run-hyphenated-library/hello-world js
./repro.sh 56-py-run-hyphenated-library/adds-one py
```

## Expected

`hello` from `hello-world` on py, as on the other backends.

## Notes

`runPyBestEffort` builds the library's own path from its Python module name
(`be-py/src/commonMain/kotlin/lang/temper/be/py/RunPython.kt:121`):

```kotlin
val pyLibraryPath = pyLibraryName?.let { pyDir.resolveDir(pyLibraryName.text) }
```

`pyLibraryName` is the `PyLibraryName` metadata, `hello_world`
(`PyBackend.kt:301`, through `pyDirToLibraryName` at `PyBackend.kt:743`),
but the directory the backend writes is named after the Temper library,
`hello-world`. For a name with no dash the two are the same, which is why
`hello` works.

The dependency paths below it (`RunPython.kt:124-135`) use `libName.text`,
the Temper name, and they cover every library that appears in
`dependencies.transitiveDependencies`, keys and values. A library is a key
there only when the build recorded a dependency from it on another library
(`registerCrossLibraryImports`, `be/src/commonMain/kotlin/lang/temper/be/FinishTmpLImports.kt:206-226`).
`adds-one` uses `int_add` from temper-core and gets an entry; `hello-world`
uses only `console.log` and gets none, so its directory is never added.

Run by hand with `temper.out/py/hello-world` in place of
`temper.out/py/hello_world` on `PYTHONPATH`, the same `python -m top`
prints `hello`.
