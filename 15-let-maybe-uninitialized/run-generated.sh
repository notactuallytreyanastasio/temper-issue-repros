#!/bin/sh
# Builds one-branch for js and py, then calls f(true) and f(false) in each.
set -u
here=$(cd "$(dirname "$0")" && pwd)
case="$here/one-branch"
"$here/../repro.sh" "$case" js > /dev/null; echo "js build exit code: $?"
(cd "$case/temper.out/js/one-branch" &&
  node -e 'import("./index.js").then(m => console.log("js f(true) =", m.f(true), " f(false) =", m.f(false)))')
"$here/../repro.sh" "$case" py > /dev/null; echo "py build exit code: $?"
(cd "$case/temper.out/py/one-branch" &&
  python3 -c 'import glob, sys; sys.path[:0] = ["."] + glob.glob("../*"); from one_branch.one_branch import f; print("py f(True) =", f(True), " f(False) =", f(False))')
