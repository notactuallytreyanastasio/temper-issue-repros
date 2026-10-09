# cpp: a library named `nan`, `time`, `random` or after another C library function does not compile, because its namespace collides with the function

The cpp backend puts each library in a top-level namespace named after it.
The headers temper-core includes declare the C library's functions at
global scope, and C++ does not allow a namespace and a function with the
same name there. Three libraries that only print `hello`:

```
$ temper run --library nan -b cpp
../nan/init.hpp:3:11: error: redefinition of 'nan' as different kind of symbol
    3 | namespace nan {
      |           ^
.../MacOSX.sdk/usr/include/math.h:540:15: note: previous definition is here
  540 | extern double nan(const char *);

$ temper run --library time -b cpp
../time/init.hpp:3:11: error: redefinition of 'time' as different kind of symbol
.../MacOSX.sdk/usr/include/_time.h:121:8: note: previous definition is here
  121 | time_t time(time_t *);

$ temper run --library random -b cpp
../random/init.hpp:3:11: error: redefinition of 'random' as different kind of symbol
.../MacOSX.sdk/usr/include/_stdlib.h:250:7: note: previous definition is here
```

All three print `hello` on js.

To see how far this goes, every lowercase name that core.hpp's headers
declare at global scope was written after them as `namespace X { void f(); }`
and compiled with the same compiler (Apple clang 21.0.0, `-std=c++14`,
macOS SDK). 510 of 578 are rejected; they are in
[`colliding-names.txt`](colliding-names.txt). Among them are names a
library could plausibly have: `clock`, `exit`, `free`, `index`, `nan`,
`printf`, `random`, `rand`, `remove`, `rename`, `signal`, `system`,
`time`. The 68 that compile are math and string functions that libc++
overloads for C++ (`sin`, `sqrt`, `abs`, `floor`, `round`, `log`,
`strchr`, ...); libraries named `sin`, `sqrt`, `log`, `floor`, `round`,
`abs`, `pow`, `exp` and `fmax` print `hello`. Two more names fail in other
ways:

```
$ temper run --library main -b cpp
main.cpp:2:5: error: redefinition of 'main' as different kind of symbol
    2 | int main() {
../main/init.hpp:3:11: note: previous definition is here
    3 | namespace main {

$ temper run --library errno -b cpp
../errno/init.hpp:3:11: error: expected identifier or '{'
    3 | namespace errno {
.../MacOSX.sdk/usr/include/sys/errno.h:81:15: note: expanded from macro 'errno'
```

Not checked with GCC or glibc, whose headers declare a different set of
names.

```sh
./repro.sh 59-cpp-library-named-like-c-function/nan cpp
./repro.sh 59-cpp-library-named-like-c-function/time cpp
./repro.sh 59-cpp-library-named-like-c-function/random cpp
./repro.sh 59-cpp-library-named-like-c-function/nan js
```

## Expected

`hello` on cpp for each.

## Notes

The backend already renames three namespaces that would collide
(`be-cpp/src/commonMain/kotlin/lang/temper/be/cpp/CppBuilder.kt:14-17`):

```kotlin
private val cppReservedNamespaces = setOf("std", "chrono", "filesystem")

internal fun safeCppNamespace(name: String): String =
    if (name in cppReservedNamespaces) "temper_$name" else name
```

Every library namespace goes through `safeCppNamespace`
(`CppBuilder.kt:462-465`, `:550`, `CppBackend.kt:128`), so `nan` would
become `temper_nan` if it were in that set. The set has none of the C
library's names, nor `main`, nor macros like `errno`.
