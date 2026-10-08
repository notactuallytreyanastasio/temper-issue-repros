# float-map

    export let names(xs: List<Float64>): List<String> {
      xs.map { (f): String => f.toString() }
    }
    
    let prices: List<Float64> = [0.25, 3.0];
    let labels = prices.map { (f): String => "$${f.toString()}" };
    
    console.log(names([1.5, 2.0]).join(",") { (s) => s });
    console.log(labels.join(",") { (s) => s });
