# a `List<Square>` passed as `List<Shape>`

    export interface Shape { area(): Int; }
    export class Square(public side: Int) extends Shape {
      public area(): Int { side * side }
    }
    
    export let total(shapes: List<Shape>): Int {
      var sum = 0;
      for (let s of shapes) { sum += s.area(); }
      sum
    }
    
    let squares: List<Square> = [new Square(2), new Square(3)];
    console.log(total(squares).toString());
