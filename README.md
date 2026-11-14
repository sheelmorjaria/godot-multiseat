# Godot MultiSeat

An open-source Godot 4 framework that lets several local players share one
authoritative game world while each keeps an independent display,
controller, HUD and private information — later extended to streaming
hybrid sessions (home gaming server with Steam Deck, TV and thin-client
participants).

**Status:** repository skeleton and v0.1 seed suite (plan Section 11,
immediate next steps). Milestone 0 (dual-display frame-pacing spike) tooling
is in place; running it needs the benchmark rig.

- Roadmap and TDD plan: [`Godot_MultiSeat_TDD_Plan.md`](Godot_MultiSeat_TDD_Plan.md)
- Contributor testing guide: [`docs/testing.md`](docs/testing.md)
- Recorded evidence: [`test-reports/`](test-reports/)

## Quick start

```bash
# L1 + L2 tests, headless (Godot 4.3-stable, gdUnit4 vendored in addons/)
test/run_tests.sh          # or: GODOT_BIN=/path/to/godot test/run_tests.sh
```

## Layout

```text
addons/multiseat/   the framework addon (core, display, input, privacy)
addons/gdUnit4/     vendored test framework (v5.1.1)
test/unit/          L1 headless unit tests
test/integration/   L2 headless integration tests
test/bench/         L3 frame-pacing benchmark scene + CSV analyzer
test-reports/       recorded manual episodes and benchmark evidence
docs/testing.md     contributor guide
```
