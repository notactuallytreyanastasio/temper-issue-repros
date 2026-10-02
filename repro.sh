#!/bin/sh
# Reproduces one case against a Temper CLI.
#
#   TEMPER=/path/to/temper ./repro.sh <case directory> [backend]
#
# The backend defaults to js. Each case directory is one Temper library
# named after the directory; its `how` file says whether the case is a
# `run`, a `test` or a `build`. Output from the CLI is printed as is.
set -u
case=${1:?usage: TEMPER=/path/to/temper ./repro.sh <case directory> [backend]}
backend=${2:-js}
temper=${TEMPER:-temper}
dir=$(cd "$case" && pwd)
name=$(basename "$dir")
rm -rf "$dir/temper.out"
case $(cat "$dir/how") in
  build) exec "$temper" build -b "$backend" -w "$dir" ;;
  *) exec "$temper" "$(cat "$dir/how")" --library "$name" -b "$backend" -w "$dir" ;;
esac
