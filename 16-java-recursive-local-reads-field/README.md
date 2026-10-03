# java: a recursive local function in a method that reads a field compiles to Java that javac rejects

A method whose recursive local function reads a field of the object builds
without a diagnostic, but the generated Java does not compile:

```temper
export class Counter(public n: Int) {
  public sumTo(): Int {
    let go(i: Int): Int {
      if (i <= 0) { 0 } else { n + go(i - 1) }
    }
    go(3)
  }
}
```

```
temper build exit code: 0
.../recursive_local/Counter.java:10: error: cannot find symbol
                    return this.n + this.go__9(i__10 - 1);
                               ^
  symbol: variable n
1 error
javac exit code: 1
```

The recursive function becomes a method of a local class, and the field
read inside it is written `this.n`. In that method `this` is the local
class, which has no `n`:

```java
public int sumTo() {
    class Local_1 {
        int go__9(int i__10) {
            if (i__10 <= 0) {
                return 0;
            } else {
                return this.n + this.go__9(i__10 - 1);
            }
        }
    }
    final Local_1 local$1 = new Local_1();
```

js and py build the same source.

```sh
./16-java-recursive-local-reads-field/compile-java.sh
```

`compile-java.sh` builds with the CLI and compiles the output with `javac`,
because `temper run -b java` on `e9ff0d25` stops on the JDK version string
`21.0.12.1` (#525).

## Expected

The field read refers to the enclosing object, for example `Counter.this.n`.

## Notes

The local class takes its name from `LOCAL_CLASS_PREFIX`
(`be-java/src/commonMain/kotlin/lang/temper/be/java/NameHelpers.kt:16`,
used at `JavaNames.kt:326`). Not traced further. A non-recursive local
function that reads the same field compiles: it becomes a lambda,
`IntUnaryOperator add__9 = i__10 -> this.n + i__10;`, where `this` is still
the `Counter`. Recursion is what moves the function into a local class.

Related: #39 (closed), the earlier failure of recursive local functions on java, which is where recursive local functions became local-class methods, as far as the issue thread shows.
