#!/bin/sh
# Builds one case for java and compiles it with javac directly.
#
#   TEMPER=/path/to/temper ./10-await-outside-async/run-java.sh <library>
#
# `temper run -b java` on e9ff0d25 cannot parse a four-part JDK version such
# as 21.0.12.1, so this skips the CLI's runner. The build itself succeeds;
# javac is where it fails.
set -u
here=$(cd "$(dirname "$0")" && pwd)
case="$here/${1:?usage: run-java.sh not-async|top-level}"
rm -rf "$case/temper.out" "$here/java-classes"
"${TEMPER:-temper}" build -b java -w "$case" || exit $?
find "$case/temper.out/java" -name '*.java' > "$here/java-sources.txt"
javac -nowarn -d "$here/java-classes" @"$here/java-sources.txt" || exit $?
main=$(cd "$case/temper.out/java" && find . -path '*/src/main/java/*Main.java' ! -path './temper-core/*' | head -1)
java -cp "$here/java-classes" "$(basename "$(dirname "$main")").$(basename "$main" .java)"
