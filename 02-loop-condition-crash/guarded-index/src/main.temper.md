# a loop whose condition guards an index

    let isSpace(cp: Int): Boolean { cp == 32 || (cp >= 9 && cp <= 13) }

    let leadingSpaces(s: String): Int {
      var b = String.begin;
      var n = 0;
      while (s.hasIndex(b) && isSpace(s[b])) { n += 1; b = s.next(b); }
      n
    }

    console.log("leadingSpaces=${leadingSpaces("  ab")}");
