# shapes that build

    export let intPanic(): Int { panic() }

    export let panicInIf(b: Boolean): Void {
      if (b) { panic(); }
    }
