# instance-method

    export class B {
      public int(k: Int): Int { k + 1 }
    }
    
    let b = new B();
    console.log(b.int(41).toString());
