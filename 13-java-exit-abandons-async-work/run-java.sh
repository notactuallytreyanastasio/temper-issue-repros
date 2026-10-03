#!/bin/sh
# Builds one library of this case for java and runs it with javac/java
# directly, printing the exit code and wall time.
#
#   ./run-java.sh never-completed
#   ./run-java.sh long-block
#
# `temper run -b java` on e9ff0d25 cannot parse a four-part JDK version such
# as 21.0.12.1, so this skips the CLI's runner.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
lib=${1:?usage: ./run-java.sh <library>}
case="$here/$lib"
classes="$here/java-classes/$lib"
rm -rf "$case/temper.out" "$classes"
"${TEMPER:-temper}" build -b java -w "$case" > /dev/null
find "$case/temper.out/java" -name '*.java' > "$here/java-sources.txt"
javac -nowarn -d "$classes" @"$here/java-sources.txt" 2> /dev/null
main=$(cd "$classes" && find . -name '*Main.class' -not -path './temper/*' | sed 's|^\./||; s|\.class$||; s|/|.|g')
start=$(date +%s)
set +e
java -cp "$classes" "$main"
status=$?
echo "exit=$status seconds=$(( $(date +%s) - start ))"
