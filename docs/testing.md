# Testing Guide

How to run, write and record tests for the Godot MultiSeat framework. The
authoritative plan is [`Godot_MultiSeat_TDD_Plan.md`](../Godot_MultiSeat_TDD_Plan.md);
this file is the hands-on contributor guide it requires (plan Section 10).
If anything here and the plan disagree, the plan wins — file an issue.

## Baseline

| Component | Version | Where |
| --- | --- | --- |
| Godot | 4.3-stable | any build; CI uses the official Linux binary |
| Test framework | gdUnit4 v5.1.1 | vendored at `addons/gdUnit4/` (no download needed) |
| Python (benchmarks only) | >= 3.9, stdlib only | for `test/bench/analyze_frame_times.py` |

A fresh clone must run `test/unit` green within ten minutes of cloning
(plan Section 10.1). If it does not, that is a documentation bug — fix this
file with your pull request.

## Moving the baseline

The version pin is load-bearing in four places: `project.godot`
(`config/features`), `pr.yml` (`godot-version`), the vendored
`addons/gdUnit4/`, and the table above. Moving it is a measured
procedure, not an edit:

1. Record a full run on the current pin: `test/run_tests.sh` plus the
   benchmark scene on the standard scenarios (rig hardware).
2. Repeat on the candidate version — same hardware, same scenarios,
   same thresholds.
3. Compare the analyzer output per scenario; a candidate that misses a
   threshold the current pin meets fails the move.
4. Record both runs under `test-reports/<build-hash>/`, update the four
   pins in one pull request, and re-verify the honesty guard if the
   gdUnit4 version moves with it (the report format is not guaranteed
   across majors).

## Running the tests locally

From the editor: open the project once (this registers the plugins and the
global classes), then use the gdUnit4 dock to run suites or single tests.

From the command line (what CI runs, wrapped for local use):

```bash
# L1 + L2, headless — the pull-request gate
test/run_tests.sh                              # defaults to test/unit + test/integration
test/run_tests.sh -a test/unit                 # a single layer
GODOT_BIN=/path/to/godot test/run_tests.sh     # if godot is not on PATH
```

The wrapper runs the same gdUnit4 command-line tool CI runs:

```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
    -a test/unit -a test/integration -c --ignoreHeadlessMode
```

(no `-d`: the debug flag makes the script debugger break on parse errors
and wait for stdin that never arrives in CI, hanging the run), and adds
the honesty contract the tool lacks in v5.1.1 — see below.

- `-a <dir>` adds a test directory; `-c` continues after failures so one red
  suite does not hide the rest.
- `--ignoreHeadlessMode` acknowledges that UI/input-pump tests cannot run
  headless. The L1/L2 suites are pure logic behind test seams and are safe
  headless; that is by design (plan Section 3.2).

Benchmark scenes need a display and are never required for ordinary pull
requests (plan Section 10.1); see *Benchmarks* below.

## The honesty guard

gdUnit4 v5.1.1 — and upstream still, as reported against 6.2.1 — exits 0
when a run discovers no test cases, for example when suites fail to parse.
A green badge can therefore hide a run of nothing, and the plan's
red-test-on-main workflow (Section 4.4) would be invisible. `test/run_tests.sh`
enforces the contract:

- **H1** the tool's own exit code is honoured;
- **H2** zero discovered test cases fails the run;
- **H3** every `*_test.gd` under each scanned `-a` path must appear as
  executed — only `Run Test Suite:` report lines count, because parse-error
  lines also carry the suite's `res://` path and would mask exactly the
  suite they prove broken;
- **H4** any `Failed to load script` under `res://test/` fails the run.

**Rule for CI:** every pipeline that invokes gdUnit4 runs behind this
contract; there is no third way to run the suite in CI. `nightly.yml` calls
the wrapper directly. The pr pipeline uses the official gdUnit4-action,
whose internal runner cannot be wrapped, so `pr.yml` verifies the same
H2/H3 properties against the action's own JUnit XML report in a follow-up
step. The XML guard's key is `(testsuite/@name, @package)` where `name` is
the file stem *including* `_test`, and each expected suite must carry at
least one testcase — verified against the real report
format. Confirmed live 2026-11-15 (run 43729843111 on the first push to
main): all suites passed on GitHub's clean runner — `version: installed`
resolved the vendored gdUnit4, and the guard's glob found the action's
reports and verified every suite with its testcases. The same run exposed
one pipeline bug outside the tests: the action's report publisher needs
`checks: write`, which `pr.yml` now grants.

One precision on what that proves: on the pr pipeline the guard and the
action's publisher read the same JUnit XML, so their agreement is
corroboration, not independent confirmation. The independent witness is
the wrapper's own `Run Test Suite:` accounting over the runner's raw
console output (H3) — the leg the nightly pipeline carries to non-dev
hardware.

Negative-path evidence (2026-11-14): against a doctored report in which
`session_test` appears with all testcases stripped, the guard fails by
name (`test/unit/session_test.gd reported zero test cases`) while the
untouched report from the same run passes — the failure mode R9's
mitigation requires.

## Branch protection

Plan Section 4.4 is enacted by the repository ruleset `require-tests-check`
(id 27318778): changes reach `main` only via pull request, and the
`unit-and-integration` check must pass first — it aggregates the gdUnit
run and the honesty guard; the publisher's `test-report.xml` check is
downstream evidence, not the gate. The bypass list is empty, maintainers
included; the emergency path is a documented ruleset exemption in the PR
that needs it. `strict_required_status_checks_policy` stays `false` while
there is a single writer — the hazard it prevents needs `main` to move
between the check run and the merge — and flips the day a second
contributor lands or PRs begin stacking within a session.

## Suite layout and identifiers

| Directory | Layer | Content |
| --- | --- | --- |
| `test/unit/` | L1 | one `*_test.gd` per class, headless, injected stubs |
| `test/integration/` | L2 | multi-node scenes, session boot, loopback netcode |
| `test/bench/` | L3 | frame-pacing benchmark scene + CSV analyzer |
| `test-reports/` | Track B | recorded manual episodes and CSV evidence |

Every test carries a stable `MS-area-number` identifier (plan Section 3.3)
quoted in the comment above the test, e.g.:

```gdscript
# MS-DISP-002: two seats cannot claim the same display.
func test_two_seats_cannot_share_one_display() -> void:
```

| Prefix | Area |
| --- | --- |
| `MS-CORE-nnn` | seat manager, seat lifecycle, session state |
| `MS-DISP-nnn` | display compositor, screen assignment, window placement |
| `MS-IN-nnn` | input isolation and device-to-seat routing |
| `MS-PRIV-nnn` | privacy and fairness layer |
| `MS-NET-nnn` | dedicated-server netcode and world replication |
| `MS-STR-nnn` | capture, encoding and streaming pipeline |
| `MS-BENCH-nnn` | automated rendering benchmarks (CSV output) |
| `MS-MAN-nnn` | recorded manual episodes |

## Writing tests that survive

The rules are short and enforced in review (plan Section 10.2):

1. **One behaviour per test**, named for it: `test_keyboard_events_are_refused`.
2. **Identifier in the comment above the test.**
3. **Contract, not internals**: assert public API behaviour only, never poke
   private fields; refactors must leave tests untouched.
4. **gdUnit4 assertion families** (`assert_that`, `assert_int`, `assert_str`)
   instead of bare conditionals, so failures read as sentences.
5. **No wall-clock sleeps.** Waiting for time is a determinism bug; wait for
   conditions or inject time through a seam (plan Section 5.3).
6. **Stubs subclass the framework seams** (`ScreenInventoryStub extends
   ScreenInventory`); no mocking library, no engine calls in L1 tests.
7. **Red before green**: every bugfix arrives with the regression test that
   failed before the fix. A pull request that adds only such a failing test
   is a valid contribution.
8. **Flaky tests are quarantined within one week** (moved to
   `test/quarantine/` with an open issue) and fixed or deleted within a
   milestone.

## Benchmarks (L3, MS-BENCH-*)

The benchmark scene renders the multi-window load and records per-frame
delta times to CSV; a plain-Python analyzer applies the thresholds and exits
non-zero on failure so CI can gate (plan Section 9.1).

```bash
# 60 s two-seat evidence capture on the benchmark rig (composed scene:
# two windows, two cameras, one shared world, moving actors)
godot --path . res://test/bench/bench_two_seat.tscn

# Tooling smoke only - the bare capture scene measures an empty
# process loop and is never evidence
godot --path . res://test/bench/bench_frame_pacing.tscn \
    ++ --csv=test-reports/<build-hash>/frame_times.csv \
    ++ --scenario=same-refresh-1080p --bench-seconds=5

# Thresholds from plan Section 6.1: >= 58 fps average, p99 <= 20 ms
python3 test/bench/analyze_frame_times.py --csv <csv> --refresh-hz 60 \
    --min-fps 58 --max-p99-ms 20.0
```

User arguments after `++` are read by the scene, not by Godot. Stutter is
defined as a frame longer than 1.5x the refresh interval. Thresholds are
declared in the plan before runs and relaxed only by pull request with
evidence attached. The full milestone 0 exit procedure — both monitor
pairs, the episode, and the same-day fallback decision — is the
[rig-day runbook](rig_day.md).

Instrument boundary, stated plainly: the CSV records the *process* frame
loop — `_process` deltas, one time series for the whole process. Process
fps is a ceiling for every window, but uneven presentation *between*
windows is invisible to it, and Godot 4.3 exposes no per-window present
timestamps. Per-display presentation is therefore verified externally on
rig day — a frame count per monitor during the captures (a 240 fps phone
camera suffices) is compared against the CSV's process average; see the
runbook's instrument-boundary note.

## Manual episodes (Track B, MS-MAN-*)

Hardware behaviour — frame pacing on physical monitor pairs, controller
hot-plug, perceived stream latency — is verified by numbered, scripted
episodes with pass criteria written before the run (plan Section 9.2).
The template is
[`test-reports/templates/manual_episode_template.md`](../test-reports/templates/manual_episode_template.md);
filled checklists are committed to `test-reports/<build-hash>/`.
MS-MAN-001 (mixed-refresh perceptual check) and MS-MAN-002 (gamepad
hot-plug) are mandatory before any milestone exit.

## Definition of done

A **pull request** is done when the `tests` pipeline is green, new or
changed behaviour is covered by tests with identifiers, and no benchmark
threshold regressed if benchmark-relevant code changed (plan Section 10.3).

A **milestone** is done when its Section 6 exit criteria hold: automated
tests green in the required pipelines, listed episodes recorded with pass
verdicts, and the traceability matrix row for any new system complete.
