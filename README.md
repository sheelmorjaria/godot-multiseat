# Godot MultiSeat

An open-source Godot 4 framework that lets several local players share one
authoritative game world while each keeps an independent display,
controller, HUD and private information — later extended to streaming
hybrid sessions (home gaming server with Steam Deck, TV and thin-client
participants).

**Status:** v0.1's automated contract set is complete and green — the
seven L1 unit suites plus both L2 integration contracts (session boot,
joypad hot-plug), all written red-first under gdUnit4 v6.2.3 on Godot
4.7.2. Milestone 0's and v0.1's remaining obligations are physical: the
dual-display frame-pacing spike and the manual episodes, sequenced
end-to-end by the rig-day runbook.

- Roadmap and TDD plan (Draft v1.3): [`Godot_MultiSeat_TDD_Plan.md`](Godot_MultiSeat_TDD_Plan.md)
- Contributor testing guide: [`docs/testing.md`](docs/testing.md) — the honesty guard, branch protection, conventions
- Milestone 0 exit runbook: [`docs/rig_day.md`](docs/rig_day.md)
- Recorded evidence: [`test-reports/`](test-reports/)

## Quick start

```bash
# L1 + L2 tests, headless (Godot 4.7.2-stable, gdUnit4 vendored in addons/)
test/run_tests.sh          # or: GODOT_BIN=/path/to/godot test/run_tests.sh
```

`main` is pull-request-gated (ruleset `require-tests-check`): the
`unit-and-integration` check — the gdUnit run plus the discovery-honesty
guard — must pass before merge, with an empty bypass list. See
[`docs/testing.md`](docs/testing.md) for the contract and its failure
modes.

## Layout

```text
addons/multiseat/   the framework addon (core, display, input, privacy)
addons/gdUnit4/     vendored test framework (v6.2.3)
test/unit/          L1: headless unit tests, one suite per class
test/integration/   L2: session boot, hot-plug, bench-scene structure
test/bench/         L3: composed two-seat rig instrument + bare capture
                    scene for tooling smokes + CSV threshold analyzer
test/run_tests.sh   the honesty wrapper every CI run goes through
test-reports/       recorded manual episodes and benchmark evidence
docs/               testing guide, rig-day runbook
```
