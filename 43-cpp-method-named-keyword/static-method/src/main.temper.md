# static-method

    export class B {
      public static bool(k: Int): Boolean { k > 0 }
    }
    
    export let f(k: Int): Boolean { B.bool(k) }
    console.log(f(1).toString());
