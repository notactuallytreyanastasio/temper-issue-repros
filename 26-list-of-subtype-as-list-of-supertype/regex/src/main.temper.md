# a `List<CodePoints>` passed to `Sequence`, which takes `List<RegexNode>`

    let { Regex, RegexNode, Sequence, CodePoints } = import("std/regex");
    
    let parts: List<CodePoints> = [new CodePoints("a"), new CodePoints("b")];
    let re = new Regex(new Sequence(parts));
    console.log(re.found("xab").toString());
