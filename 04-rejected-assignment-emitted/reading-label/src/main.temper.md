# a type error the build reports, and then emits anyway

    export let readingSeconds(words: Int): Int {
      words * 60 / 238
    }

    export let readingLabel(words: Int): String {
      var seconds = readingSeconds(words);
      seconds = "slow";
      "${seconds} seconds"
    }
