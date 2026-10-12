#!/bin/sh
# Builds the null-value case for java and runs it with javac/java directly.
# `temper run -b java` on ffba652a cannot parse a four-part JDK version such
# as 21.0.12.1 (#525), so this skips the CLI's runner.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
case="$here/null-value"
rm -rf "$case/temper.out" "$here/java-classes"
"${TEMPER:-temper}" build -b java -w "$case" > /dev/null
find "$case/temper.out/java" -name '*.java' > "$here/java-sources.txt"
javac -nowarn -d "$here/java-classes" @"$here/java-sources.txt" 2> /dev/null
java -cp "$here/java-classes" null_value.NullValueMain
