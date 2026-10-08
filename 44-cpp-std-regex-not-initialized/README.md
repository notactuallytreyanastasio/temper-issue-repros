# cpp: a module that imports only classes from std/regex never initializes it, and building a `Regex` segfaults

```temper
let { Regex, Sequence, CodePoints } = import("std/regex");

let re = new Regex(new Sequence([new CodePoints("a"), new CodePoints("b")]));
console.log(re.found("xab").toString());
```

```
$ ./repro.sh 44-cpp-std-regex-not-initialized/classes cpp
## exception.msg: .../temper.out/cpp/classes/build/main failed: exit code = 139
```

js and py print `true`.

The generated `global_init_init()` builds the regex without first calling
`temper_std::global_init_regex()`:

```cpp
  void global_init_init() {
    static bool initialized = false;
    if (initialized) {
      return;
    }
    initialized = true;
    console_0 = temper::core::Console::get_console();
    re = temper_std::Regex::make(...);
```

Rebuilt with `-g`, lldb stops in `temper::core::List::get<int>(list=nullptr, index=97)`
called from `temper_std::RegexFormatter::pushCode` (`std/regex.cpp:521`),
under `Regex::make`: a module-level list in std/regex that its init
function would have set.

Importing one value as well, `Begin`
([`withvalue`](withvalue/src/main.temper.md)), makes the generated code
call `temper_std::global_init_regex();` first, and cpp prints `true`.

## Expected

`true`: every imported module initialized before the importer's top level
runs, whatever kind of name is imported from it.

## Notes

From reading `be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppTranslator.kt`:
`gatherDependencyInitCalls` (line 3092) emits one `global_init_*` call per
entry in `importedNames`, and `preprocessImports` fills that map only for
imports that have a `localName` (`import.localName?.name ?: continue`,
line 168). I have not checked which of the three imports here lack
a local name, so that is a guess at the cause. I did not try other std
modules, or a user library that exports only classes.
