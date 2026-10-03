# a Void method and a Void function that end in panic()

    export class Gate {
      public fail(): Void { panic(); }
    }

    export let failFn(): Void { panic(); }
