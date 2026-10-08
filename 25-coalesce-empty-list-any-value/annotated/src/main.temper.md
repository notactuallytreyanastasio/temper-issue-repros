# annotated

    export let count(items: List<String>?): Int {
      let xs: List<String> = items ?? [];
      xs.length
    }
    
    console.log(count(["a", "b"]).toString());
    console.log(count(null).toString());
