# A rejected assignment is emitted as written, and the failed build's output runs

`temper build` reports a type error and exits 1, but it still writes the
library, with the rejected assignment translated as if it were valid. The
output loads and returns a value of the wrong type.

## Source

[`reading-label/src/main.temper.md`](reading-label/src/main.temper.md):

```temper
export let readingSeconds(words: Int): Int {
  words * 60 / 238
}

export let readingLabel(words: Int): String {
  var seconds = readingSeconds(words);
  seconds = "slow";
  "${seconds} seconds"
}
```

```
[-work/src/main.temper.md:9+6-22]@G: Cannot assign to Int32 from String
Build failed
```

## What the build writes

js, `temper.out/js/reading-label/reading_label.internal.js`:

```js
export function readingLabel(words_2) {
  let seconds_3 = readingSeconds(words_2);
  seconds_3 = "slow";
  return String(seconds_3.toString()) + " seconds";
};
```

py, `temper.out/py/reading-label/reading_label/reading_label.py`:

```python
def reading_label(words_4: 'int4', /) -> 'str5':
    seconds_6: 'int4' = reading_seconds(words_4)
    seconds_6 = 'slow'
    return _str_cat_35(_int_to_string_36(seconds_6), ' seconds')
```

[`run-emitted.sh`](run-emitted.sh) builds the case for each backend and
calls what it wrote:

```
[-work/src/main.temper.md:9+6-22]@G: Cannot assign to Int32 from String
build exit code: 1
js readingLabel(500) = "slow seconds"
[-work/src/main.temper.md:9+6-22]@G: Cannot assign to Int32 from String
build exit code: 1
py reading_label(500) = 'slow seconds'
```

## Expected

Either no output from a failed build, or output in which the rejected
assignment fails at run time with its diagnostic.

Today rejected code generally does not fail at run time: a typed `let`, a
wrongly typed `return` and a call with a wrongly typed argument are all
emitted as written too, and the functional test
`semantics/type-checked-locals` documents a static type error that does
not stop execution as intended. Whether it should fail is a design
question; draft #514 makes it fail and lists what changes.

## Why it matters

A tool that rebuilds on every save and loads whatever lands in
`temper.out`, such as a dev server's file watcher, picks up this output
after a failed build, and a page built from it would read "slow seconds".
The diagnostic is in `temper.out/-logs/0000.log`, but nothing in the
backend's own directory, `temper.out/js/reading-label/`, marks the library
as the product of a failed build.
