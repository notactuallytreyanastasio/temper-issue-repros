#!/bin/sh
# Builds recursive-local for java with the CLI, then compiles the output with javac.
set -u
here=$(cd "$(dirname "$0")" && pwd)
case="$here/recursive-local"
"$here/../repro.sh" "$case" java > /dev/null; echo "temper build exit code: $?"
find "$case/temper.out/java" -name '*.java' > "$here/java-sources.txt"
javac -nowarn -d "$here/java-classes" @"$here/java-sources.txt" 2> "$here/javac.txt"
rc=$?
grep -v '^Note:' "$here/javac.txt"
echo "javac exit code: $rc"
