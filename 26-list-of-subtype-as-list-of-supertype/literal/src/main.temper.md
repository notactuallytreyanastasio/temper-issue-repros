# a list literal of `Square`s returned as `List<Shape>`

    export interface Shape { area(): Int; }
    export class Square(public side: Int) extends Shape {
      public area(): Int { side * side }
    }
    
    export let squares(n: Int): List<Shape> { [new Square(n), new Square(n + 1)] }
    
    let shapes = squares(2);
    console.log((shapes[0].area() + shapes[1].area()).toString());
