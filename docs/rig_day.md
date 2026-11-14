# Rig Day: Milestone 0 Exit Runbook

The one-page procedure for the day the dual-display rig is available. It
discharges plan Section 6.1 (MS-BENCH-001, MS-BENCH-002, MS-MAN-001) using
only committed tooling: the benchmark scene, the analyzer and the episode
template. Thresholds are already declared — they are not negotiated on the
day. Budget roughly 90 minutes including one monitor swap.

Milestone 0's question (plan Section 6.1): can one Godot process drive two
borderless windows on two monitors, each rendering a camera of a shared
world, at stable frame rates with vsync enabled? If the answer is no, the
fallback decision is taken **that day**, not later.

## 0. Preflight (~10 min)

- [ ] Rig: benchmark GPU idle (no other GPU load), both monitor pairs
      reachable, cable types noted (DisplayPort/HDMI).
- [ ] `godot --version` prints 4.3.stable; `python3 --version` >= 3.9.
- [ ] `test/run_tests.sh` exits 0 on the rig machine — the wrapper, never
      an ad-hoc godot invocation (docs/testing.md, the honesty guard).
- [ ] Record the build and open the evidence directory:
      `BUILD=$(git rev-parse --short=12 HEAD)` and
      `OUT=test-reports/${BUILD}-$(date -u +%Y%m%d-%H%M%S)`; `mkdir -p "${OUT}"`.
- [ ] Note renderer, driver version and whether the run uses a dev or
      release template in `${OUT}/notes.md` (release-template export is not
      required at milestone 0; record whichever is used).

## 1. MS-BENCH-001 — same-refresh pair (~20 min)

- [ ] Attach the same-refresh pair (both panels 1080p60); confirm in the
      OS display settings; no scaling tricks.
- [ ] Capture 60 s — the scene default duration; **never** pass
      `--bench-seconds` for an evidence run:
      `godot --path . res://test/bench/bench_frame_pacing.tscn ++ --csv="${OUT}/frame_times_same_refresh.csv" --scenario=same-refresh-1080p`
- [ ] Gate (exit 0 required; paste the analyzer line into `${OUT}/notes.md`):
      `python3 test/bench/analyze_frame_times.py --csv "${OUT}/frame_times_same_refresh.csv" --label same-refresh-1080p --refresh-hz 60`
      (thresholds default from plan Section 6.1: >= 58 fps average,
      p99 <= 20 ms.)

## 2. MS-BENCH-002 — mixed-refresh pair, 144 + 60 Hz (~20 min)

- [ ] Swap to the mixed pair. Record panel models and connection types in
      `${OUT}/notes.md` — mixed-refresh vsync is risk R1, the most likely
      reason the no-fork strategy could fail (plan Section 8).
- [ ] Capture:
      `godot --path . res://test/bench/bench_frame_pacing.tscn ++ --csv="${OUT}/frame_times_mixed_144_60.csv" --scenario=mixed-144-60`
- [ ] Analyze with `--refresh-hz 60`: pacing is judged against the slower
      panel; record that choice in the notes. Stutter classification
      (frames > 1.5x refresh) comes from the analyzer output line.

## 3. MS-MAN-001 — perceptual episode on the mixed pair (~25 min)

- [ ] Copy `test-reports/templates/manual_episode_template.md` to
      `${OUT}/ms-man-001.md` and write the pass criteria **before** playing
      (Appendix B): no visible stutter on either display; no input
      delivered to the wrong seat after deliberate window-focus changes;
      one gamepad unplug/replug recovers.
- [ ] Five minutes of play on the mixed pair; alternate window focus
      deliberately; unplug and replug one gamepad once.
- [ ] Verdict PASS/FAIL with tester name and date; on FAIL attach the
      same-run CSV from step 2.

## 4. Verdict and the same-day fallback decision

- [ ] If either threshold is missed on the mixed pair, plan Section 6.1
      requires the fallback decision **today**: separate processes, or
      engine-level investigation. Record the decision and the evidence in
      `${OUT}/decision.md`, open the tracking issue, and update risk R1 in
      the plan's risk register via pull request with evidence attached.
- [ ] Thresholds are relaxed only by pull request with the reason recorded
      next to the evidence — never by re-running until the numbers fit.

## 5. Land the evidence

- [ ] Commit `${OUT}`: CSVs are evidence and are never regenerated
      (test-reports/README.md).
- [ ] Push and watch the first real `pr` and `nightly` runs: confirm the
      action's report step and the honesty guard agree
      (docs/testing.md — this confirmation is outstanding until a remote
      exists).

On a full pass, milestone 0 exits and the v0.1 framework work proceeds
with the multi-window architecture confirmed; the traceability matrix and
risk register update through the same evidence-carrying pull request.
