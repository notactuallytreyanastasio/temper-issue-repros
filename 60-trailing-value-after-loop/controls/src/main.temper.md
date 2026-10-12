# the same loops without one of the two jumps

    let returnOnly(inputs: List<String>): Int {
      for (var i = 0; i < inputs.length; ++i) {
        if (inputs[i] != "") { return i; }
      }
      -7
    }

    let continueOnly(inputs: List<String>): Int {
      for (var i = 0; i < inputs.length; ++i) {
        if (inputs[i] == "") { continue; }
      }
      -7
    }

    console.log("returnOnly([\"\"]) = ${returnOnly([""]).toString()}");
    console.log("continueOnly([\"\"]) = ${continueOnly([""]).toString()}");
