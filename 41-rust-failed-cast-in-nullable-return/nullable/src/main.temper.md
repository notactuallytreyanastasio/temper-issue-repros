# a failing `as` in a function returning `Text? throws Bubble`

    export sealed interface Node {}
    export class Text(public s: String) extends Node {}
    export class Num(public n: Int) extends Node {}
    
    export let asText(v: Node?): Text? throws Bubble {
      if (v == null) { return null; }
      v as Text
    }
    
    let describe(v: Node?): String throws Bubble {
      let t = asText(v);
      if (t == null) { "null" } else { t.s }
    }
    
    console.log(describe(new Text("hi")) orelse "bubbled");
    console.log(describe(null) orelse "bubbled");
    console.log(describe(new Num(1)) orelse "bubbled");
