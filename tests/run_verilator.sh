#!/usr/bin/env bash
set -uo pipefail
ulimit -c 0
cd "$(dirname "$0")/.."
mkdir -p tests/build
verilator --version | tee tests/build/version.txt
verilator --lint-only --timing -Wall -Wno-fatal --top-module main project_1.srcs/sources_1/new/*.v > tests/build/lint.log 2>&1
lint_status=$?
echo "Lint exit status: $lint_status (warnings retained in tests/build/lint.log)"
verilator --lint-only --timing -Wall -Wno-fatal --top-module main -y project_1.srcs/sources_1/new project_1.srcs/sources_1/new/main.v > tests/build/active_lint.log 2>&1
verilator --binary --timing --trace -Wno-fatal --top-module cpu_regression --Mdir tests/build/obj -j 4 -y project_1.srcs/sources_1/new tests/cpu_regression.sv > tests/build/build.log 2>&1 || { tail -60 tests/build/build.log; exit 1; }
tests/build/obj/Vcpu_regression "$@" 2>&1 | tee tests/build/results.log
exit ${PIPESTATUS[0]}
