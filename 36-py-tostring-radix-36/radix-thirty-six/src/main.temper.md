# `toString(36)` on Int32 and Int64

    let show(a: Int, b: Int64): Void {
      console.log("Int32 ${a.toString()} in radix 36: ${a.toString(36)}");
      console.log("Int64 ${b.toString()} in radix 36: ${b.toString(36)}");
    }
    show(35, 35i64);
    show(-2147483647 - 1, -9223372036854775807i64 - 1i64);
