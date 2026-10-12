# control: a call with a type argument

    let identity<T>(x: T): T { x }

    console.log(identity<Int>(5).toString());
