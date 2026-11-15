#!/usr/bin/env bash
# Local + CI test runner (plan Section 10.1, docs/testing.md).
#
# Wraps the gdUnit4 command-line tool and enforces the discovery-honesty
# contract that gdUnit4 v5.1.1 does not provide on its own (the zero-exit
# behaviour is still unfixed upstream, reported against 6.2.1):
#
#   H1  the tool's own exit code is honoured — failures fail;
#   H2  a run that discovers ZERO test cases fails (the tool exits 0 there);
#   H3  every *_test.gd under each scanned -a path must be reported as
#       executed — one unparseable suite must not hide among healthy ones;
#   H4  any "Failed to load script" under res://test/ fails the run.
#
# Rule (docs/testing.md): every CI invocation of gdUnit4 runs behind this
# honesty contract. The pr pipeline uses the official gdUnit4-action, whose
# internal runner cannot be wrapped — pr.yml therefore checks the action's
# own JUnit XML report for the same H2/H3 properties in a follow-up step.
#
# Usage:
#   test/run_tests.sh [extra gdUnit4 args]      # default: -a test/unit -a test/integration
#   GODOT_BIN=/path/to/godot test/run_tests.sh  # if godot is not on PATH
#
# Exit codes: 0 all green · 1 failures or honesty violation · 2 usage.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	if [ -x "${GODOT_BIN}" ]; then
		:   # relative or absolute path works even if not on PATH
	else
		echo "godot not found: set GODOT_BIN=/path/to/godot (4.7.2-stable baseline)." >&2
		exit 2
	fi
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

ARGS=("$@")
if [ ${#ARGS[@]} -eq 0 ]; then
	ARGS=(-a test/unit -a test/integration)
fi

# Collect the -a paths this run will scan, so the wrapper can compute the
# expected suite set itself (only -a is supported by the tool in v5.1.1).
SCAN_PATHS=()
i=0
while [ $i -lt ${#ARGS[@]} ]; do
	if [ "${ARGS[$i]}" = "-a" ]; then
		if [ $((i + 1)) -ge ${#ARGS[@]} ]; then
			echo "test/run_tests.sh: -a needs a path argument" >&2
			exit 2
		fi
		i=$((i + 1))
		path="${ARGS[$i]}"
		path="${path#./}"                       # normalize for res:// mapping
		if [ ! -d "$path" ] && [ ! -f "$path" ]; then
			echo "FAIL: test path '$path' does not exist" >&2
			exit 1
		fi
		SCAN_PATHS+=("$path")
	fi
	i=$((i + 1))
done

# H3: the expectation set — every suite file under (or equal to) each -a path.
EXPECTED=()
for path in ${SCAN_PATHS+"${SCAN_PATHS[@]}"}; do
	if [ -d "$path" ]; then
		while IFS= read -r file; do
			EXPECTED+=("res://${file#./}")
		done < <(find "$path" -type f -name '*_test.gd' | LC_ALL=C sort)
	else
		EXPECTED+=("res://$path")
	fi
done
if [ ${#EXPECTED[@]} -eq 0 ]; then
	echo "FAIL: no *_test.gd sources found under the scanned paths." >&2
	exit 1
fi

LOG="$(mktemp /tmp/multiseat-tests.XXXXXX.log)"
CLEAN="$(mktemp /tmp/multiseat-tests.XXXXXX.clean)"
trap 'rm -f "${LOG}" "${CLEAN}"' EXIT

set +e
# No -d here, unlike gdUnit4's own runtest.sh: the debug flag makes the
# script debugger break on parse errors and wait at a `debug>` prompt for
# stdin that never arrives in CI, hanging the run. Without it, parse
# errors are printed and skipped — which H3/H4 then turn into failures.
"${GODOT_BIN}" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	-c --ignoreHeadlessMode "${ARGS[@]}" 2>&1 | tee "${LOG}"
EXIT_CODE="${PIPESTATUS[0]}"
set -e

sed $'s/\x1b\\[[0-9;]*m//g' "${LOG}" > "${CLEAN}"

HONESTY=0

# H2: zero test cases discovered — the tool exits 0 in this state (v5.1.1).
if grep -q "No test cases found" "${CLEAN}"; then
	echo "" >&2
	echo "FAIL: no test cases were discovered — suites failed to parse, or the test path is wrong." >&2
	echo "      A run with zero tests is red by definition (plan Section 4.4: red must be visible)." >&2
	HONESTY=1
fi

# H4: explicit load errors under res://test/ (belt and braces to H3).
if grep -qE 'Failed to load script "res://test/' "${CLEAN}"; then
	echo "" >&2
	grep -E 'Failed to load script "res://test/' "${CLEAN}" | sort -u >&2
	echo "FAIL: script load errors above — an unparsable suite is skipped silently otherwise." >&2
	HONESTY=1
fi

# H3: each expected suite must appear in the run report as executed. Only
# "Run Test Suite:" header lines count — parse-error lines also carry the
# res:// path and would otherwise mask exactly the suites they prove broken.
EXECUTED="$(grep -E 'Run Test Suite:' "${CLEAN}" | grep -oE 'res://[^[:space:]]+_test\.gd' | sort -u)"
MISSING=0
for suite in "${EXPECTED[@]}"; do
	if ! printf '%s\n' "${EXECUTED}" | grep -qxF "${suite}"; then
		echo "FAIL: suite ${suite} was not executed (failed to parse, or is not a test suite)." >&2
		MISSING=1
	fi
done
if [ ${MISSING} -ne 0 ]; then
	HONESTY=1
fi

if [ ${HONESTY} -ne 0 ]; then
	echo "" >&2
	echo "Discovered suites this run:" >&2
	printf '%s\n' ${EXECUTED:+"${EXECUTED}"} | sed 's/^/  /' >&2
	exit 1
fi

exit "${EXIT_CODE}"
