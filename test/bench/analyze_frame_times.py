#!/usr/bin/env python3
"""Frame-time threshold analyzer for the MS-BENCH scenarios (plan Section 9.1).

Reads the CSV written by test/bench/bench_frame_pacing.gd (columns
``frame,delta_ms``), computes the statistics the plan thresholds use, and
exits non-zero when a threshold is missed so CI can gate on it.

Thresholds default to the milestone 0 definition (plan Section 6.1):
at least 58 fps average per window over the run and p99 frame time at or
under 20 ms for two-window scenarios at 1080p. Stutter is defined as a
frame longer than 1.5x the refresh interval (plan Section 9.1).

No Godot dependency; Python >= 3.9, stdlib only.
"""

from __future__ import annotations

import argparse
import csv
import math
import sys
from dataclasses import dataclass

DEFAULT_MIN_FPS = 58.0
DEFAULT_MAX_P99_MS = 20.0
STUTTER_REFRESH_FACTOR = 1.5


@dataclass
class FrameStats:
    label: str
    frames: int
    wall_seconds: float
    mean_fps: float
    mean_ms: float
    p50_ms: float
    p95_ms: float
    p99_ms: float
    max_ms: float
    stutters: int
    stutter_rate: float


def percentile_nearest_rank(sorted_ms: list[float], p: float) -> float:
    """Nearest-rank percentile: the smallest value whose rank is >= p% of N."""
    if not sorted_ms:
        return float("nan")
    rank = max(1, math.ceil(p / 100.0 * len(sorted_ms)))
    return sorted_ms[rank - 1]


def read_frame_times(path: str) -> list[float]:
    """Read a bench CSV and return delta times in milliseconds."""
    deltas: list[float] = []
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        header = next(reader, None)
        if header != ["frame", "delta_ms"]:
            raise ValueError(
                f"{path}: unexpected header {header!r}, expected ['frame', 'delta_ms']"
            )
        for lineno, row in enumerate(reader, start=2):
            if not row:
                continue
            if len(row) != 2:
                raise ValueError(f"{path}:{lineno}: expected 2 columns, got {row!r}")
            try:
                deltas.append(float(row[1]))
            except ValueError as exc:
                raise ValueError(f"{path}:{lineno}: bad delta_ms {row[1]!r}") from exc
    if not deltas:
        raise ValueError(f"{path}: no frame rows found")
    return deltas


def compute_stats(label: str, deltas_ms: list[float], refresh_hz: float) -> FrameStats:
    wall_seconds = sum(deltas_ms) / 1000.0
    sorted_ms = sorted(deltas_ms)
    stutter_threshold_ms = STUTTER_REFRESH_FACTOR * 1000.0 / refresh_hz
    stutters = sum(1 for d in deltas_ms if d > stutter_threshold_ms)
    mean_fps = len(deltas_ms) / wall_seconds if wall_seconds > 0 else 0.0
    return FrameStats(
        label=label,
        frames=len(deltas_ms),
        wall_seconds=wall_seconds,
        mean_fps=mean_fps,
        mean_ms=sum(deltas_ms) / len(deltas_ms),
        p50_ms=percentile_nearest_rank(sorted_ms, 50),
        p95_ms=percentile_nearest_rank(sorted_ms, 95),
        p99_ms=percentile_nearest_rank(sorted_ms, 99),
        max_ms=sorted_ms[-1],
        stutters=stutters,
        stutter_rate=100.0 * stutters / len(deltas_ms),
    )


def evaluate(stats: FrameStats, min_fps: float, max_p99_ms: float) -> list[str]:
    """Return the list of threshold violations (empty list = pass)."""
    violations = []
    if stats.mean_fps < min_fps:
        violations.append(
            f"mean fps {stats.mean_fps:.1f} is below the minimum {min_fps:.1f}"
        )
    if stats.p99_ms > max_p99_ms:
        violations.append(
            f"p99 frame time {stats.p99_ms:.2f} ms exceeds the maximum {max_p99_ms:.2f} ms"
        )
    return violations


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--csv",
        action="append",
        required=True,
        help="bench CSV to analyze (frame,delta_ms); repeatable",
    )
    parser.add_argument(
        "--label",
        default="",
        help="scenario label for the report line (e.g. same-refresh-1080p)",
    )
    parser.add_argument("--refresh-hz", type=float, default=60.0, help="refresh interval of the scenario")
    parser.add_argument("--min-fps", type=float, default=DEFAULT_MIN_FPS)
    parser.add_argument("--max-p99-ms", type=float, default=DEFAULT_MAX_P99_MS)
    args = parser.parse_args(argv)

    failed = False
    for path in args.csv:
        label = args.label or path
        try:
            deltas = read_frame_times(path)
        except (OSError, ValueError) as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            failed = True
            continue
        stats = compute_stats(label, deltas, args.refresh_hz)
        stutter_ms = STUTTER_REFRESH_FACTOR * 1000.0 / args.refresh_hz
        print(
            f"{stats.label}: {stats.frames} frames over {stats.wall_seconds:.1f} s | "
            f"mean {stats.mean_fps:.1f} fps | frame time ms "
            f"p50 {stats.p50_ms:.2f} / p95 {stats.p95_ms:.2f} / p99 {stats.p99_ms:.2f} / "
            f"max {stats.max_ms:.2f} | stutters {stats.stutters} ({stats.stutter_rate:.2f}%, "
            f"> {stutter_ms:.2f} ms)"
        )
        violations = evaluate(stats, args.min_fps, args.max_p99_ms)
        if violations:
            failed = True
            for violation in violations:
                print(f"FAIL {stats.label}: {violation}", file=sys.stderr)
        else:
            print(f"PASS {stats.label}: >= {args.min_fps:.1f} fps and p99 <= {args.max_p99_ms:.2f} ms")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
