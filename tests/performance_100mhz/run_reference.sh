#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
cd "$(dirname "$0")/../.."
mkdir -p tests/performance_100mhz/build
verilator --binary --timing --trace -Wno-fatal --top-module reference_regression \
  --Mdir tests/performance_100mhz/build/obj -j 4 -y project_1.srcs/sources_1/new \
  tests/performance_100mhz/reference_regression.sv tests/performance_100mhz/verify_validity.sv \
  > tests/performance_100mhz/build/build.log 2>&1 || {
    tail -60 tests/performance_100mhz/build/build.log
    exit 1
  }
tests/performance_100mhz/build/obj/Vreference_regression "$@" 2>&1 | tee tests/performance_100mhz/build/results.log
