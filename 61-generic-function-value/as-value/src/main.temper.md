# a generic function passed as a value, with its type argument

    let identity<T>(x: T): T { x }
    let apply(f: fn (Int): Int, x: Int): Int { f(x) }

    console.log("before");
    console.log(apply(identity<Int>, 5).toString());
