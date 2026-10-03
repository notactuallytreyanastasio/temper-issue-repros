# a class named `Err`, in a module with a function that can fail

`Err` collides once the module has a function that bubbles, since that is
where the generated Rust writes `Err(...)`.

    class Err(public n: Int) {}
    let half(x: Int): Int throws Bubble {
      if (x % 2 != 0) { bubble(); }
      return x / 2;
    }
    console.log("n=${new Err(1).n} half=${half(4) orelse -1}");
