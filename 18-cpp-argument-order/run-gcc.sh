#!/bin/sh
# Builds later-read for cpp, then compiles and runs the generated C++ with
# x86-64 g++ 14 in Docker, the way `temper run -b cpp` does on Linux.
#
#   TEMPER=/path/to/temper ./18-cpp-argument-order/run-gcc.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
lib=$here/later-read
"$here/../repro.sh" "$lib" cpp
cd "$lib/temper.out/cpp"
exec docker run --rm --platform linux/amd64 -v "$PWD":/w -w /w/later-read gcc:14 sh -c \
  'g++ -I.. -std=c++14 *.cpp $(ls ../*/*.cpp | grep -v /later-read/) -o /tmp/main && /tmp/main'
