#!/bin/sh
# Builds two-reads for rust, compiles host/main.rs against the generated
# crate, and runs it with a 20 second limit. host/main.rs calls Gauge::bump
# from 8 threads. Exit code 142 means the alarm fired and the program hung.
set -u
here=$(cd "$(dirname "$0")" && pwd)
case="$here/two-reads"
"$here/../repro.sh" "$case" rust > /dev/null || exit 1
host="$case/temper.out/host"
mkdir -p "$host/src"
cp "$here/host/main.rs" "$host/src/main.rs"
cat > "$host/Cargo.toml" <<TOML
[package]
name = "host"
version = "0.0.0"
edition = "2021"

[dependencies]
two-reads = { path = "../rust/two-reads" }
temper-core = { path = "../rust/temper-core" }
TOML
cargo build --release -q --manifest-path "$host/Cargo.toml" || exit 1
perl -e 'alarm 20; exec @ARGV' "$host/target/release/host"
echo "exit code: $?"
