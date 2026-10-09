# A library name with a digit is imported under a different name on py and rust, so `temper run` fails: `f64str` as `f64_str`, `radix-36` as `radix36`

Two libraries with the same program, named `f64str` and `radix-36`:

```temper
var x = 41;
x = x + 0;
console.log("hello");
console.log((x + 1).toString());
```

(the addition keeps `radix-36` clear of
[`56-py-run-hyphenated-library`](../56-py-run-hyphenated-library), which
would otherwise also stop it on py.)

py:

```
$ temper run --library f64str -b py
    import f64_str as module
ModuleNotFoundError: No module named 'f64_str'

$ temper run --library radix-36 -b py
    import radix36 as module
ModuleNotFoundError: No module named 'radix36'
```

rust:

```
error[E0433]: cannot find module or crate `f64_str` in this scope
 --> src/main.rs:2:5
  |
2 |     f64_str::init(None).unwrap().run_all_blocking();
  |     ^^^^^^^ use of unresolved module or unlinked crate `f64_str`

error[E0433]: cannot find module or crate `radix36` in this scope
 --> src/main.rs:2:5
  |
2 |     radix36::init(None).unwrap().run_all_blocking();
  |     ^^^^^^^ use of unresolved module or unlinked crate `radix36`
```

js, java, lua and cpp print `hello` and `42` for both.

What each backend wrote:

| | py package directory | py import in `top.py` | cargo package | crate name rust uses |
|---|---|---|---|---|
| `f64str` | `f64str/f64str/` | `f64_str` | `f64str` (crate `f64str`) | `f64_str` |
| `radix-36` | `radix-36/radix_36/` | `radix36` | `radix-36` (crate `radix_36`) | `radix36` |

```sh
./repro.sh 57-library-name-with-digit/f64str py
./repro.sh 57-library-name-with-digit/f64str rust
./repro.sh 57-library-name-with-digit/radix-36 py
./repro.sh 57-library-name-with-digit/radix-36 rust
./repro.sh 57-library-name-with-digit/radix-36 js
```

## Expected

`hello` and `42` on py and rust for both names.

## Notes

Both backends turn the dashed name into a snake-case one with
`IdentStyle.Dash.convertTo(IdentStyle.Snake, ...)`, which re-splits the name
into words and puts `_` after a run of digits but never before one
(`name/src/commonMain/kotlin/lang/temper/name/identifiers/IdentStyle.kt:98-125`).
So `f64str` becomes `f64_str` and `radix-36` becomes `radix36`. The tools
on the other side only swap `-` for `_`.

py: the package directory comes from `toModuleFileName`
(`be-py/src/commonMain/kotlin/lang/temper/be/py/PyBackend.kt:352-356`,
`PyModule.kt:145`), which gives `f64str` and `radix_36`. The
`PyLibraryName` metadata that `top.py` imports comes from
`pyDirToLibraryName` (`PyBackend.kt:301`, `:743-747`), which uses
`IdentStyle`. The module file inside the package is named the `IdentStyle`
way too (`f64_str.py`, `radix36.py`), and its `__init__.py` imports it by
that name, so only the top-level name disagrees.

rust: `PackageNaming.crateName` is `packageName.dashToSnake()`
(`be-rust/src/commonMain/kotlin/lang/temper/be/rust/RustNames.kt:23-26`,
`RustExt.kt:545`), and `main.rs` calls `${crateName}::init`
(`RustBackend.kt:156`). Cargo names the crate for package `radix-36`
`radix_36`. A library that imports from `radix-36` refers to it by
`crateName` too (`RustExt.kt:569`, `RustBackend.kt:398-401`) while declaring
the cargo dependency by `packageName` (`RustBackend.kt:170`), and fails the
same way on rust, with `radix36::`. On py such a library runs, because
imports between libraries use the package directory's name.
