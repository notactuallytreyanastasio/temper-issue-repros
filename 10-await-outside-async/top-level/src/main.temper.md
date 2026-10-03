# await at the top level of a module

    let b = new PromiseBuilder<Int>();
    b.complete(3);
    let x = await b.promise orelse -1;
    console.log(x.toString());
