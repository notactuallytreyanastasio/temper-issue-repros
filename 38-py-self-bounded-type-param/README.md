# py: a type parameter bounded by a type that mentions itself, like `<T extends Ord<T>>`, raises NameError on import

py emits the bound of a `TypeVar` as a plain expression, so a bound that
refers to the type variable being defined, or to a class defined later in
the file, is evaluated before the name exists:

```temper
interface Ord<T> {
  public less(other: T): Boolean;
}
class N(public v: Int) extends Ord<N> {
  public less(other: N): Boolean { v < other.v }
}
let smaller<T extends Ord<T>>(a: T, b: T): T { if (a.less(b)) { a } else { b } }
console.log(smaller(new N(3), new N(2)).v.toString());
```

js, java, lua, rust, cpp and the interpreter print `2`. py:

```
    T_6 = TypeVar3('T_6', bound = _Ord[T_6])
NameError: name 'T_6' is not defined. Did you mean: 'T_2'?
```

When the interface's own parameter is bounded by the interface
([`interface-type-param`](interface-type-param/src/main.temper.md)), the
class is not defined yet either:

```temper
interface Ord<T extends Ord<T>> {
  public less(other: T): Boolean;
}
```

```
    T_1 = TypeVar2('T_1', bound = _Ord[T_1], covariant = True)
NameError: name '_Ord' is not defined. Did you mean: 'ord'?
```

The same NameError on `T_5` comes from a class parameter,
`class Pick<T extends Ord<T>>`. A bound by a plain interface declared later
in the file (`let show<T extends Later>`) works.

```sh
./repro.sh 38-py-self-bounded-type-param/function-type-param py
./repro.sh 38-py-self-bounded-type-param/interface-type-param py
```

## Expected

`2` and `false` on py, as on js.

## Notes

`defineTypeVars` in `be-py/src/commonMain/kotlin/lang/temper/be/py/PyTranslator.kt`
passes `translateNominalType(upperBounds[0])` as `bound` (line 681) without
quoting it. The class-definition code a few hundred lines up already quotes
type arguments for this reason (`Py.TypeStr`, around line 318). `TypeVar`
accepts a string bound; in the Python 3.14 that Temper's venv uses,

```python
T = TypeVar('T', bound='Ord[T]', covariant=True)
class Ord(Generic[T]): pass
```

runs and gives `T.__bound__ == ForwardRef('Ord[T]')`. The multi-bound branch
(line 685 on) has the same shape and is not tested here.

Not checked: csharp.
