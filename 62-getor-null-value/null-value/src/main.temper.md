# getOr for a key whose value is null

    let show(label: String, value: String): Void { console.log("${label}: [${value}]"); }

    let builder = new MapBuilder<String, String?>();
    builder["n"] = null;
    show("builder has n", builder.has("n").toString());
    show("builder get n", do { builder["n"] ?? "null" } orelse "bubble");
    show("builder getOr n", builder.getOr("n", "fallback") ?? "null");
    show("builder getOr absent", builder.getOr("absent", "fallback") ?? "null");

    let map = builder.toMap();
    show("map has n", map.has("n").toString());
    show("map get n", do { map["n"] ?? "null" } orelse "bubble");
    show("map getOr n", map.getOr("n", "fallback") ?? "null");
    show("map getOr absent", map.getOr("absent", "fallback") ?? "null");
