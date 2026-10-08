# `C.n = ...` on a `static var` builds into a write to a string on js, and crashes the compiler inside a static method

A class can declare `public static var n`, and `C.n` reads it. Assigning
`C.n = ...` goes wrong two ways, depending on where the assignment is.

From top level or from a module function
([`at-top-level`](at-top-level/src/main.temper.md)), the build succeeds
with no diagnostic and exit 0, and the assignment target in the output is
the compiler's printout of the type value:

```temper
class C {
  public static var n: Int = 0;
}
C.n = C.n + 1;
console.log("${C.n}");
```

js:

```js
C.n;
"C__0: Type".n = 1;
console.log(String(C.n.toString()));
```

```
TypeError: Cannot create property 'n' on string 'C__0: Type'
```

py:

```python
('<<lang.temper.value.TType: Type, lang.temper.value.Value: C__0: Type>>', NotImplemented)[1].n = 1
```

```
AttributeError: 'NotImplementedType' object has no attribute 'n' and no __dict__ for setting new attributes
```

lua emits `nil['n'] = 1;` and the run fails. rust emits
`std::any::TypeId::of::<C>().set_n(1);` and stops on `E0599: no method
named set_n found for struct TypeId`. java's output fails `javac` with
`cannot find symbol`. The js class has `static get n()` and no setter.

The read-modify-write was folded to `= 1`, so the right side was
evaluated; only the target is lost. Putting the assignment in
`let bump(): Void { C.n = C.n + 1; }` gives the same js output inside
`bump`.

From a static method of the class
([`in-static-method`](in-static-method/src/main.temper.md)), the
frontend reports a malformed assignment and the compiler then throws:

```temper
class C {
  public static var n: Int = 0;
  public static bump(): Void { C.n = C.n + 1; }
}
C.bump();
console.log("${C.n}");
```

```
5: atic bump(): Void { C.n = C.n + 1; }
                       ┗━┛
[-work/src/main.temper.md:5+35-38]@G: Malformed assignment
Exception in thread "main" java.lang.ClassCastException: class lang.temper.value.CallTree cannot be cast to class lang.temper.value.LeftNameLeaf
	at lang.temper.be.tmpl.TmpLControlFlowKt.combineDeclarationsOnto(TmpLControlFlow.kt:1041)
	at lang.temper.be.tmpl.TmpLControlFlowKt.fixupBlockContent(TmpLControlFlow.kt:1118)
```

The same on js and py, exit 1.

```sh
./repro.sh 23-static-var-assignment/at-top-level js
./repro.sh 23-static-var-assignment/in-static-method js
```

## Expected

`1` from both programs. If static `var`s are not meant to be assignable,
a diagnostic at `static var` or at the assignment, and no output.

## Notes

The docs for `@static` (`docs/for-users/temper-docs/docs/reference/builtins.md`,
around line 4050) show only `static let`, and say static members are
accessed via the type name. They say nothing either way about `static
var`. The only `static var` I found in the repository outside the cpp
backend's comments is a decorator test,
`frontend/src/commonTest/resources/lang/temper/frontend/stage-tests/syntax-macro/who-decorates-the-decorators/work/test/test.temper:3`;
no functional test assigns one.

"Malformed assignment" in the static method case comes from
`frontend/src/commonMain/kotlin/lang/temper/frontend/CaptureBlockResultsInTemporaries.kt:466`,
which handles an assignment whose left side is not a `NameLeaf`. The crash
is the cast `stmt.tree.child(1) as LeftNameLeaf` at
`be/src/commonMain/kotlin/lang/temper/be/tmpl/TmpLControlFlow.kt:1041`,
which assumes the same. Both point at `C.n = ...` reaching those stages as
an assignment to a call tree instead of being turned into a static setter
call. That is from reading the two sites and the stack trace; I did not
trace where the conversion should happen.

Writing `n = n + 1` with no type name inside the static method is
correctly rejected with `Type name required for accessing static member`.
csharp and cpp were not run.
