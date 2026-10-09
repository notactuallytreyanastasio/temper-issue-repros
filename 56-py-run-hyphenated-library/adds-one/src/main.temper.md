# adds-one

The same program, plus an `Int` addition that is not folded away. Its
support code comes from temper-core, so the build records a dependency from
this library on temper-core.

    var x = 41;
    x = x + 0;
    console.log("hello");
    console.log((x + 1).toString());
