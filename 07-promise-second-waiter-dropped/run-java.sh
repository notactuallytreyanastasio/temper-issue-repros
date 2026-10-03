#!/bin/sh
# Builds the two-waiters case for java and runs it with javac/java directly.
# `temper run -b java` on e9ff0d25 cannot parse a four-part JDK version such
# as 21.0.12.1, so this skips the CLI's runner.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
case="$here/two-waiters"
rm -rf "$case/temper.out" "$here/java-classes"
"${TEMPER:-temper}" build -b java -w "$case" > /dev/null
find "$case/temper.out/java" -name '*.java' > "$here/java-sources.txt"
javac -nowarn -d "$here/java-classes" @"$here/java-sources.txt" 2> /dev/null
java -cp "$here/java-classes" two_waiters.TwoWaitersMain
