# only classes imported from std/regex

    let { Regex, Sequence, CodePoints } = import("std/regex");
    
    let re = new Regex(new Sequence([new CodePoints("a"), new CodePoints("b")]));
    console.log(re.found("xab").toString());
