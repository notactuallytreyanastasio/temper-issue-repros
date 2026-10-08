#!/bin/sh
# Runs `temper test -b java` three times on a copy of stale-report:
#   1. step 1 as committed (passes),
#   2. step 2 (javac fails) in the same temper.out,
#   3. step 2 again after deleting temper.out.
#
#   TEMPER=/path/to/temper ./run-sequence.sh
set -u
temper=${TEMPER:-temper}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)/stale-report
cp -R "$here/stale-report" "$work"
rm -rf "$work/temper.out"
run() {
  echo "\$ temper test -b java   # $1"
  "$temper" test --library stale-report -b java -w "$work" > "$work/../out.txt" 2>&1
  rc=$?
  grep -E '^Test|^Tests|^## exception.msg|\[ERROR\].*\.java' "$work/../out.txt" | sort -u
  echo "exit $rc"
  echo
}
run "step 1"
cp "$here/step2.temper.md" "$work/src/main.temper.md"
run "step 2, same temper.out"
echo "test cases in the surefire report:"
grep -ho '<testcase name="[^"]*"' "$work"/temper.out/java/stale-report/target/surefire-reports/*.xml
echo
rm -rf "$work/temper.out"
run "step 2, temper.out deleted"
