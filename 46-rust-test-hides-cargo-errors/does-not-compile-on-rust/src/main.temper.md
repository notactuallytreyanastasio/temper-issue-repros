# A constant that the rust backend emits as Rust that does not compile

    export let k(): Int { 0xb5c0fbcfi64.toInt32Unsafe() }

    test("k is the low 32 bits") { test =>
      assert(k() == -1245643825) { "got ${k().toString()}" }
    }

    test("a test that would pass") { test =>
      assert(true) { "unreachable" }
    }
