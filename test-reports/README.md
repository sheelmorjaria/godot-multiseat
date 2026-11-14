# Test Reports

Evidence directory (plan Section 9.3). Every automated benchmark run leaves
a CSV artifact; every manual episode leaves a filled checklist.

## Layout

```text
test-reports/
  <build-hash>/            # one directory per recorded build
    frame_times.csv        # raw per-frame capture (MS-BENCH-*)
    ms-man-001.md          # filled episode checklist(s)
    notes.md               # optional: rig changes, driver versions
  templates/
    manual_episode_template.md
  README.md
```

`<build-hash>` is the 12-character git hash of the tested build plus a UTC
timestamp, e.g. `9f83ab21c44e-20261114-1430`. This directory is the
project's performance history: results are committed, never regenerated.

## Thresholds and regressions

Current thresholds live in the plan (Section 6.1) and in the nightly
pipeline invocation of `analyze_frame_times.py`. A regression is defined
quantitatively (plan Section 9.3): a scenario whose p99 worsens by more
than 15 percent across five consecutive nightly runs opens an issue
automatically. Any relaxation of a threshold requires a pull request that
records the reason next to the evidence that forced it.
