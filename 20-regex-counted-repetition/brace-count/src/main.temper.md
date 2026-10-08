# counted repetition in a regex literal

    let { ... } = import("std/regex");

    let show(re: Regex, s: String): String {
      re.find(s).full.value orelse "no match"
    }

    console.log("/[0-9]{3}/ on x123y:   ${show(/[0-9]{3}/, "x123y")}");
    console.log("/[0-9]{2,3}/ on x123y: ${show(/[0-9]{2,3}/, "x123y")}");
    console.log("/x{3}/ on ax{3}b:      ${show(/x{3}/, "ax{3}b")}");
    console.log("Repeat(3, 3) on x123y: ${show(new Repeat(/[0-9]/.data, 3, 3).compiled(), "x123y")}");
