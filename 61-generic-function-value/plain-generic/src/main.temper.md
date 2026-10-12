# the same, without the type argument

    let identity<T>(x: T): T { x }
    let apply(f: fn (Int): Int, x: Int): Int { f(x) }

    console.log(apply(identity, 5).toString());
