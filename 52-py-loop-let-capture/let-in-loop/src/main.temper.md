# A `let` in a loop body, and a `for of` variable, captured by closures

    let run(xs: List<Int>, n: Int): String {
      let fs = new ListBuilder<fn (): Int>();
      for (var i = 0; i < n; i += 1) {
        let s = i * 10;
        fs.add(fn (): Int { s });
      }
      for (let x of xs) {
        fs.add(fn (): Int { x });
      }
      fs.join(",") { f => f().toString() }
    }
    console.log(run([7, 8, 9], 3));
