# Float64 division by a zero the compiler cannot see

    let show(a: Float64, b: Float64): String {
      "${(a / b).toString() orelse "Bubble"} ${(a % b).toString() orelse "Bubble"}"
    }
    var z = 0.0;
    z = z;
    console.log("1.0 / 0.0: ${show(1.0, z)}");
    console.log("0.0 / 0.0: ${show(0.0, z)}");
    console.log("1.0 / -0.0: ${show(1.0, -z)}");
