#!/bin/sh
# Builds reading-label, which the build rejects, then runs what it wrote
# anyway: the js module under node and the py module under python3.
set -u
here=$(cd "$(dirname "$0")" && pwd)
"$here/../repro.sh" "$here/reading-label" js
echo "build exit code: $?"
(cd "$here/reading-label/temper.out/js/reading-label" &&
  node -e 'import("./index.js").then(m => console.log("js readingLabel(500) =", JSON.stringify(m.readingLabel(500))))')
"$here/../repro.sh" "$here/reading-label" py
echo "build exit code: $?"
(cd "$here/reading-label/temper.out/py/reading-label" &&
  python3 -c 'import glob, sys; sys.path[:0] = ["."] + glob.glob("../*"); from reading_label.reading_label import reading_label; print("py reading_label(500) =", repr(reading_label(500)))')
