# a loop with a `return` and a `continue` or `break`, then a trailing value

    let afterContinue(inputs: List<String>): Int {
      for (var i = 0; i < inputs.length; ++i) {
        if (inputs[i] == "") { continue; }
        return i;
      }
      -7
    }

    let afterBreak(inputs: List<String>): Int {
      for (var i = 0; i < inputs.length; ++i) {
        if (inputs[i] == "") { break; }
        return i;
      }
      -7
    }

    console.log("afterContinue([\"\"]) = ${afterContinue([""]).toString()}");
    console.log("afterContinue([\"\", \"\"]) = ${afterContinue(["", ""]).toString()}");
    console.log("afterBreak([\"\"]) = ${afterBreak([""]).toString()}");
