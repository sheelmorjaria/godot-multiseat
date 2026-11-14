#!/usr/bin/env bash
# Local test runner (plan Section 10.1, docs/testing.md).
#
# Wraps the gdUnit4 command-line tool with one guard the tool itself does
# not provide in v5.1.1: a run that discovers ZERO test cases must fail.
# Without this guard, a rename that breaks every suite's parse would show
# a green CI badge while running nothing — and the plan's red-test-on-main
# workflow (plan Section 4.4) would be invisible.
#
# Usage:
#   test/run_tests.sh [extra gdUnit4 args]      # default: -a test/unit -a test/integration
#   GODOT_BIN=/path/to/godot test/run_tests.sh  # if godot is not on PATH
#
# Exit codes: 0 all green · 1 failures or zero tests discovered · 2 usage.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	if [ -x "${GODOT_BIN}" ]; then
		:   # relative or absolute path works even if not on PATH
	else
		echo "godot not found: set GODOT_BIN=/path/to/godot (4.3-stable baseline)." >&2
		exit 2
	fi
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then
	ARGS=(-a test/unit -a test/integration)
fi

LOG="$(mktemp /tmp/multiseat-tests.XXXXXX.log)"
trap 'rm -f "${LOG}"' EXIT

set +e
"${GODOT_BIN}" --headless --path . -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	-c --ignoreHeadlessMode "${ARGS[@]}" 2>&1 | tee "${LOG}"
EXIT_CODE="${PIPESTATUS[0]}"
set -e

# gdUnit4 v5.1.1 exits 0 when it discovers no test cases at all (for
# example when every suite fails to parse). Treat that as failure.
if grep -q "No test cases found" "${LOG}"; then
	echo "" >&2
	echo "FAIL: no test cases were discovered — suites failed to parse, or the test path is wrong." >&2
	echo "      A run with zero tests is red by definition (plan Section 4.4: red must be visible)." >&2
	exit 1
fi

exit "${EXIT_CODE}"
