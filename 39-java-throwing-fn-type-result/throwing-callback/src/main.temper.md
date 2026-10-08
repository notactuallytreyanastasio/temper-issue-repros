# throwing-callback

    export let applyAll<T>(xs: List<String>, f: fn (String): T throws Bubble): List<T> throws Bubble {
      let out = new ListBuilder<T>();
      for (let x of xs) { out.add(f(x)); }
      out.toList()
    }
    
    export let applyOne(x: String, f: fn (String): String throws Bubble): String throws Bubble {
      f(x)
    }
    
    let nums = applyAll(["1", "22"]) { (s: String): Int throws Bubble => s.toInt32() } orelse panic();
    console.log(nums.join(",") { (n) => n.toString() });
    console.log(applyOne("a") { (s: String): String throws Bubble => s } orelse panic());
