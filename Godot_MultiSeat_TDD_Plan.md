# Test-Driven Development Plan

**Godot MultiSeat Engine: local multi-seat and streaming hybrid roadmap**

- Scope: full roadmap — local v0.1 to v1.0 and streaming Phases 1 to 4
- Test framework: gdUnit4 on Godot 4
- Audience: maintainers and external contributors
- Status: Draft v1.3 · 15 November 2026

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Purpose, Scope and Guiding Principles](#2-purpose-scope-and-guiding-principles)
  - [2.1 Scope of This Plan](#21-scope-of-this-plan)
  - [2.2 TDD Principles for an Engine Framework](#22-tdd-principles-for-an-engine-framework)
  - [2.3 The Two-Track Strategy](#23-the-two-track-strategy)
- [3. Test Taxonomy: The Four-Layer Model](#3-test-taxonomy-the-four-layer-model)
  - [3.1 Layer Definitions](#31-layer-definitions)
  - [3.2 Headless Versus Display-Bound: A Decision Table](#32-headless-versus-display-bound-a-decision-table)
  - [3.3 Test Identifiers and Naming Conventions](#33-test-identifiers-and-naming-conventions)
- [4. Tooling and Continuous Integration](#4-tooling-and-continuous-integration)
  - [4.1 Standardising on gdUnit4](#41-standardising-on-gdunit4)
  - [4.2 Repository Layout](#42-repository-layout)
  - [4.3 CI Pipeline Design](#43-ci-pipeline-design)
  - [4.4 Contributor Workflow and PR Gates](#44-contributor-workflow-and-pr-gates)
- [5. The Red-Green-Refactor Cycle in Practice](#5-the-red-green-refactor-cycle-in-practice)
  - [5.1 Worked Example: SeatManager](#51-worked-example-seatmanager)
  - [5.2 Worked Example: InputRouter](#52-worked-example-inputrouter)
  - [5.3 Designing Test Seams in Godot](#53-designing-test-seams-in-godot)
- [6. Phase-by-Phase Test Plan](#6-phase-by-phase-test-plan)
  - [6.1 Milestone 0: The Dual-Display Spike](#61-milestone-0-the-dual-display-spike)
  - [6.2 v0.1 — Two Seats, Two Monitors, Two Gamepads](#62-v01--two-seats-two-monitors-two-gamepads)
  - [6.3 v0.2 — Four Seats and Automatic Display Assignment](#63-v02--four-seats-and-automatic-display-assignment)
  - [6.4 v0.3 — Privacy Layer and Per-Seat Interfaces](#64-v03--privacy-layer-and-per-seat-interfaces)
  - [6.5 v0.4 — Profiling and Per-Seat Quality Scaling](#65-v04--profiling-and-per-seat-quality-scaling)
  - [6.6 v1.0 — API Freeze and Reusable Extension](#66-v10--api-freeze-and-reusable-extension)
  - [6.7 Streaming Phase 1 — Dedicated Server](#67-streaming-phase-1--dedicated-server)
  - [6.8 Streaming Phase 2 — Single Streamed Player](#68-streaming-phase-2--single-streamed-player)
  - [6.9 Streaming Phase 3 — Independent Multi-Stream Sessions](#69-streaming-phase-3--independent-multi-stream-sessions)
  - [6.10 Streaming Phase 4 — Hybrid Sessions](#610-streaming-phase-4--hybrid-sessions)
- [7. Traceability Matrix](#7-traceability-matrix)
- [8. Risk-Based Test Priorities](#8-risk-based-test-priorities)
- [9. Hardware Test Protocol: Automated and Manual](#9-hardware-test-protocol-automated-and-manual)
  - [9.1 Automated Benchmark Scenes](#91-automated-benchmark-scenes)
  - [9.2 Manual Episodes and Checklists](#92-manual-episodes-and-checklists)
  - [9.3 Recording and Trending Results](#93-recording-and-trending-results)
- [10. Contributor Guide and Quality Gates](#10-contributor-guide-and-quality-gates)
  - [10.1 Running the Tests Locally](#101-running-the-tests-locally)
  - [10.2 Writing Tests That Survive](#102-writing-tests-that-survive)
  - [10.3 Definition of Done and Release Gates](#103-definition-of-done-and-release-gates)
- [11. Conclusions and Immediate Next Steps](#11-conclusions-and-immediate-next-steps)
- [Appendix A: Reference gdUnit4 Test Suite](#appendix-a-reference-gdunit4-test-suite)
- [Appendix B: Sample Manual Test Episode Checklist](#appendix-b-sample-manual-test-episode-checklist)

---

## 1. Executive Summary

This document defines the test-driven development (TDD) plan for **Godot MultiSeat**, an open-source Godot 4 framework that lets several local players share one authoritative game world while each keeps an independent display, controller, HUD and private information. It covers the full roadmap: the local multi-seat milestones from v0.1 to v1.0, and the four streaming phases that extend the engine onto a home gaming server with Steam Deck, television and thin-client participants.

The plan standardises on **gdUnit4** as the single test framework, organised into a four-layer model: headless unit tests (L1), headless integration tests (L2), GPU-bound rendering benchmarks (L3) and end-to-end LAN sessions (L4). Because a large part of the risk in this project is physical - multi-monitor vsync behaviour, controller hot-plugging, video-streaming latency - the plan pairs the automated pyramid with a formal, recorded manual protocol. This is the two-track strategy: everything that can run in continuous integration must run in continuous integration; everything that cannot must still be verified by a named, repeatable episode with pass and fail criteria written before it is run.

Three decisions shape the sequencing. First, the dual-display frame-pacing spike is milestone zero: its pass and fail thresholds are fixed in this document before any gameplay code exists, because multi-window vsync is the existential risk of the project. Second, v0.1 accepts gamepads only, since stock Godot cannot distinguish physical keyboards, and a test explicitly asserts that keyboard input is refused. Third, the project rule that Godot is only forked when a verified limitation forces it gains a testing corollary: **no engine modification is justified until a reproducible failing check demonstrates the limitation.** The intended audience is external contributors; accordingly, every pull request gate, naming convention and workflow needed to contribute tests is specified here.

## 2. Purpose, Scope and Guiding Principles

### 2.1 Scope of This Plan

The plan governs all testing for the Godot MultiSeat framework and its reference game, following the milestone line already agreed: v0.1 through v1.0 for local multi-seat play on one machine, then the four streaming phases for a home-server architecture in which clients either render locally or receive a per-player video stream. Section 6 states, for every one of those milestones, which tests come into existence and what exit criteria apply, and Section 3.3 fixes the identifier areas that name them. Anything outside the addon and its example game - engine modifications above all - is in scope only through the risk register of Section 8.

### 2.2 TDD Principles for an Engine Framework

The framework follows the classical red-green-refactor loop: write a failing test that names one behaviour, implement the minimum that makes it pass, then restructure without changing behaviour. For a framework rather than a single game, two additions matter. **Regression-first bugfixes**: every defect is first reproduced by a new failing test, which then becomes the permanent regression guard. **Contract tests over implementation tests**: tests assert public API behaviour - inputs, outputs, error cases - and never reach into private internals, so refactors stay free while the contract stays locked.

TDD also extends the project fork rule. The agreed strategy is to modify the Godot engine only when a specific limitation cannot be solved through public APIs or GDExtension. Testing makes that rule enforceable: a limitation claim must be accompanied by a reproducing check before any fork work begins, which converts architectural debates into evidence.

### 2.3 The Two-Track Strategy

Godot runs headless in continuous integration, but windows, vsync, GPUs, monitors and network latency do not behave identically in a headless runner; pretending otherwise produces a green CI badge and a broken living room. The plan therefore separates verification into two tracks. **Track A (automated)** covers all logic that is deterministic or can be made deterministic through test seams: seat lifecycle, input routing, display mapping, privacy filtering, netcode, session state. **Track B (human-verified)** covers behaviour that only exists with real hardware: frame pacing on physical monitor pairs, controller hot-plug, perceived stream latency. Track B episodes are scripted, numbered, recorded in the repository, and repeated at every milestone exit - informal ad-hoc checking is not verification.

## 3. Test Taxonomy: The Four-Layer Model

### 3.1 Layer Definitions

Every test in the project belongs to exactly one layer. The layer determines where the test runs, how fast it is, and what it is allowed to depend on. The deliberate consequence is an inverted effort distribution: most tests are L1 because they are cheap, and each step up the pyramid is smaller, more expensive and less frequent.

**Table 1:** The four test layers

| Layer | Name | Runs where | Typical content | Cadence |
| --- | --- | --- | --- | --- |
| L1 | Unit | CI, headless | Single classes: SeatManager, InputRouter, DisplayMapper, VisibilityFilter; pure logic with injected stubs | Every commit |
| L2 | Integration | CI, headless | Multi-node scenes, session boot, loopback netcode, headless server with scripted clients | Every commit |
| L3 | Rendering benchmark | Self-hosted runner, GPU + displays | Frame-time capture across 1-4 windows, per-seat quality scaling, capture and encode load | Nightly + milestone exit |
| L4 | End-to-end session | LAN with real clients | Dedicated server plus Steam Deck or PC clients, soak sessions, hybrid fairness | Weekly + release |

### 3.2 Headless Versus Display-Bound: A Decision Table

Deciding where a behaviour must be verified is itself a design decision, made once here rather than argued per pull request. The rule: if the behaviour can be expressed against an injected provider, it is an L1 concern; if it only manifests through the operating system compositor, GPU or a physical display, it belongs to L3 or the manual protocol.

**Table 2:** Verification level by behaviour class

| Behaviour | Verified at | Rationale |
| --- | --- | --- |
| Window placement on a real monitor | L3 | Requires a display server and physical screen |
| Frame pacing under vsync | L3 + manual | Compositor and monitor refresh behaviour; see Section 9 |
| Keyboard and mouse per seat | Deferred (GDExtension) | Stock Godot does not separate physical keyboards; risk R2 |
| Shared-world determinism | L2 | Fixed seed plus scripted inputs, state hash compared |
| Dedicated server netcode | L2, soak at L4 | ENet runs headless; latency needs a real network |
| Perceived stream latency | Manual | Human judgement on motion-to-photon delay; protocol in Section 9 |

### 3.3 Test Identifiers and Naming Conventions

Every test carries a stable identifier used in code review, milestone exit criteria, the traceability matrix and recorded test reports. The scheme is MS-area-number, with areas aligned to the engine systems. Test files live under `test/unit`, `test/integration` or `test/bench` and are named after the class under test, for example `seat_manager_test.gd`. Test method names state the behaviour: `test_two_seats_cannot_share_one_display`. The identifier is quoted in the comment above each test, so a failure in CI names its owning requirement immediately.

**Table 3:** Test identifier areas

| Prefix | Area | First introduced |
| --- | --- | --- |
| MS-CORE-nnn | Seat manager, seat lifecycle, session state | v0.1 |
| MS-DISP-nnn | Display compositor, screen assignment, window placement | v0.1 |
| MS-IN-nnn | Input isolation and device-to-seat routing | v0.1 |
| MS-PRIV-nnn | Privacy and fairness layer, information isolation | v0.3 (seeded v0.1) |
| MS-NET-nnn | Dedicated-server netcode and world replication | Streaming Phase 1 |
| MS-STR-nnn | Capture, encoding and streaming pipeline | Streaming Phase 2 |
| MS-BENCH-nnn | Automated rendering benchmarks with CSV output | Milestone 0 |
| MS-MAN-nnn | Recorded manual episodes | Milestone 0 |

## 4. Tooling and Continuous Integration

### 4.1 Standardising on gdUnit4

The project uses **gdUnit4** as its only GDScript test framework: an embedded framework for Godot 4 with an in-editor test inspector, a command-line runner, fluent assertions and an official GitHub Action. Standardising on one framework keeps contributor instructions short, makes CI uniform, and keeps the assertion vocabulary consistent across the suite (`assert_that`, `assert_int`, `assert_str`). The choice is about contributor clarity rather than capability; GUT would also serve.

### 4.2 Repository Layout

Test code lives beside the framework code it verifies, in a layout that mirrors the layer model. The framework itself is an addon so that example games and external projects can install it without forking.

**Listing 1:** Repository layout with the four layers

```text
godot-multiseat/
  addons/multiseat/              # the framework addon
    plugin.cfg
    core/seat_manager.gd, seat.gd, session.gd
    display/screen_inventory.gd   # seam over DisplayServer
    display/display_mapper.gd
    input/input_router.gd
    privacy/visibility_filter.gd
  addons/gdUnit4/                # vendored test framework
  test/unit/                     # L1: *_test.gd per class
  test/integration/              # L2: session_boot, netcode_loopback
  test/bench/                    # L3: bench_frame_pacing + analyzer
  .github/workflows/pr.yml, nightly.yml
  docs/testing.md                # contributor guide (Section 10)
  test-reports/                 # recorded episodes and CSV trends
```

### 4.3 CI Pipeline Design

Continuous integration is organised around the layer model: the pull-request gate runs only what is cheap and deterministic; hardware-dependent verification runs nightly on a self-hosted runner; releases require the full matrix plus signed-off manual episodes. Budgets are part of the design, because slow gates train contributors to skip them.

**Table 4:** CI pipelines

| Pipeline | Runner | Scope | Budget | Blocking |
| --- | --- | --- | --- | --- |
| pr | GitHub-hosted ubuntu | L1 + L2 headless via gdUnit4-action | 10 min | Merge blocked on failure |
| nightly | Self-hosted, GPU + two displays | L3 benchmarks; CSV artifacts uploaded; threshold comparison script | 45 min | Advisory; blocking for milestone exit |
| soak | LAN, real clients | L4 session of 2+ hours, logs uploaded | Manual start | Release gate |
| release | Full matrix | All pipelines + all MS-MAN episodes re-run and recorded | As needed | Release gate |

The pull-request workflow uses the official action with every version pinned: action `@v1.4.2`, Godot 4.3, and `version: installed` so CI exercises the vendored gdUnit4 rather than downloading the latest release, whose newer majors drop support for the pinned Godot baseline. Checkout uses `actions/checkout@v5`, the v4 line running on the now-deprecated Node 20 runtime. The workflow grants its token `contents: read` and `checks: write`; without the write grant the publisher cannot create its check run, and the pipeline fails after the tests have passed - a constraint the first live run (43729843111) exposed. The invocation also passes `--ignoreHeadlessMode`: gdUnit4 v5.x refuses headless execution unless the flag acknowledges it, so a refusal points at a configuration regression rather than a mystery. Input names follow the gdUnit4-action README.

**Listing 2:** Pull-request gate using the official gdUnit4 action

```yaml
# .github/workflows/pr.yml (excerpt)
name: tests
on: [push, pull_request]
jobs:
  unit-and-integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: godot-gdunit-labs/gdUnit4-action@v1.4.2
        with:
          godot-version: "4.3"
          version: "installed"   # run the vendored gdUnit4, not the latest
          paths: "test/unit,test/integration"
          headless: true
          # gdUnit4 v5.x refuses headless runs unless acknowledged
          arguments: "--ignoreHeadlessMode"
```

One property of the runner must be fenced by policy rather than trusted: gdUnit4 exits 0 when no test cases are discovered, so a suite that fails to parse, or a path that matches nothing, is indistinguishable from a pass - and the behaviour persists in current framework releases. Every CI invocation of the runner therefore enforces its own discovery. Direct invocations go through the wrapper `test/run_tests.sh`, which fails when no suite executes or when any `*_test.gd` in the tree is missing from the executed set, naming the offending path. The pr pipeline invokes the action's internal runner directly and cannot be wrapped, so it carries an equivalent follow-up step asserting, against the action's JUnit report, that every `*_test.gd` appears as a suite with at least one testcase. A green badge must mean that tests ran.

### 4.4 Contributor Workflow and PR Gates

The project is open source, so the testing rules must survive contact with external contributors, and they are deliberately mechanical. Every pull request that changes framework code under `addons/multiseat/` must contain the tests that exercise the change; every bugfix must contain the regression test that failed before the fix. Reviewers check that new tests carry an MS identifier and assert public behaviour only. Branch protection marks the pr pipeline as a required check. A first-time contributor who adds only a failing test reproducing a documented defect has made a valid, mergeable contribution once CI shows it red on main and green on the fix branch.

## 5. The Red-Green-Refactor Cycle in Practice

### 5.1 Worked Example: SeatManager

The seat manager is the first framework class and the template for the loop. **Red**: the test below names two behaviours - unique sequential seat ids, and display assignment validated against an injected screen inventory rather than the operating system. The test fails because no SeatManager exists.

**Listing 3:** Red: failing tests naming the seat manager contract

```gdscript
# test/unit/seat_manager_test.gd
class_name SeatManagerTest
extends GdUnitTestSuite

# MS-CORE-001: seats receive unique, sequential ids.
func test_create_seat_returns_unique_ids() -> void:
    var manager := SeatManager.new()
    assert_int(manager.create_seat().id).is_equal(0)
    assert_int(manager.create_seat().id).is_equal(1)

# MS-DISP-001: display assignment is validated against the
# injected screen inventory, never against the OS directly.
func test_assign_display_rejects_unknown_screen() -> void:
    var manager := SeatManager.new()
    manager.screen_inventory = ScreenInventoryStub.new([0, 1])
    var seat := manager.create_seat()
    assert_that(manager.assign_display(seat.id, 2)).is_false()
    assert_int(seat.display_id).is_equal(-1)

# MS-DISP-002: two seats cannot claim the same display.
func test_two_seats_cannot_share_one_display() -> void:
    var manager := SeatManager.new()
    manager.screen_inventory = ScreenInventoryStub.new([0, 1])
    var a := manager.create_seat()
    var b := manager.create_seat()
    assert_that(manager.assign_display(a.id, 0)).is_true()
    assert_that(manager.assign_display(b.id, 0)).is_false()
```

**Green**: the smallest implementation that satisfies the three tests. It validates through the injected inventory and keeps a claim map so a display can only be owned once. Nothing else is added - no signals, no logging, no window creation - because no test asks for them yet.

**Listing 4:** Green: minimal implementation

```gdscript
# addons/multiseat/core/seat_manager.gd
class_name SeatManager
extends RefCounted

var screen_inventory: ScreenInventory

var _next_id := 0
var _seats := {}
var _display_owner := {}

func create_seat() -> Seat:
    var seat := Seat.new(_next_id)
    _next_id += 1
    _seats[seat.id] = seat
    return seat

func assign_display(seat_id: int, screen: int) -> bool:
    if screen_inventory == null:
        return false
    if not screen_inventory.has_screen(screen):
        return false
    if _display_owner.has(screen):
        return false
    _seats[seat_id].display_id = screen
    _display_owner[screen] = seat_id
    return true
```

**Refactor**: once green, structure follows. The display-claim bookkeeping moves into a dedicated `DisplayMapper`, and `SeatManager` delegates. The tests from Listing 3 run unchanged after the refactor, which is the point: they were written against the contract, not the layout. The stub is deliberately trivial - a subclass of the `ScreenInventory` seam returning a fixed list - so it lives in the test directory and adds no mocking dependency.

### 5.2 Worked Example: InputRouter

Input isolation is where the project encodes a platform reality as an executable rule. Godot reports the same `device` index for the keyboard and the first controller, so v0.1 is gamepads-only by design, not by omission. The test makes that a permanent, visible contract: keyboard events must be refused, and joypad events must route by device id.

**Listing 5:** Red: input isolation as an executable rule

```gdscript
# test/unit/input_router_test.gd (excerpt)
class_name InputRouterTest
extends GdUnitTestSuite

# MS-IN-001: joypad events route by device id, not window focus.
func test_joypad_events_route_by_device_id() -> void:
    var router := InputRouter.new()
    router.assign_device(0, 0)   # seat 0 owns joypad 0
    router.assign_device(1, 1)   # seat 1 owns joypad 1
    var event := InputEventJoypadMotion.new()
    event.device = 1
    event.axis = JOY_AXIS_LEFT_X
    event.axis_value = 1.0
    assert_int(router.route(event)).is_equal(1)

# MS-IN-003: stock Godot cannot isolate keyboards, so v0.1
# actively refuses keyboard input instead of mis-routing it.
func test_keyboard_events_are_refused() -> void:
    var router := InputRouter.new()
    router.assign_device(0, 0)
    var event := InputEventKey.new()
    event.device = 0
    assert_int(router.route(event)).is_equal(-1)
```

The green step is a two-branch router: joypad button and motion events return the seat bound to their device id, and everything else returns -1. Ten lines with no engine dependencies - and the refusal branch is what makes the v0.1 gamepads-only rule executable rather than documented. The full listing appears in Appendix A alongside the other seed suites.

### 5.3 Designing Test Seams in Godot

A test seam is a place where the framework lets test code substitute a provider for an engine service. Three seams are mandated by this plan, because they convert otherwise untestable classes into L1 material. **Screen inventory**: nothing in the framework may call `DisplayServer` screen functions directly; they go through the `ScreenInventory` interface, so a stub answers in CI and the real adapter answers at runtime. **Action sources**: the session consumes abstract action states per seat, so local joypads and, in the streaming phases, remote network input feed the same interface - which is also how a streamed player and a local player become indistinguishable to the simulation. **Randomness and time**: physics seeds and clock-driven behaviour are injected, enabling the determinism tests that hash world state after a scripted input sequence. Each seam exists because a test needed it; seams without tests are speculation.

## 6. Phase-by-Phase Test Plan

For each milestone this section names the tests that come into existence and the exit criteria that declare it done. A milestone exits only when every new automated test is green in its required pipeline, every listed manual episode is recorded with a pass verdict, and the definition-of-done bullets hold. Sequencing follows the risk order of Section 8, not feature order.

### 6.1 Milestone 0: The Dual-Display Spike

The spike answers one question before any framework code exists: can one Godot process drive two borderless windows on two monitors, each rendering a camera of a shared world, at stable frame rates with vsync enabled? Thresholds are declared here in advance so the result cannot be negotiated afterwards. The mixed-refresh pair is included because Godot has open issues around vsync with multiple monitors at different refresh rates - this is the most likely reason the no-fork strategy could fail.

**Table 5:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-BENCH-001 | L3 | Same-refresh pair, vsync on: per-window fps and p99 frame time within thresholds |
| MS-BENCH-002 | L3 | Mixed-refresh pair (144+60 Hz): frame-time distribution, stutter classification |
| MS-MAN-001 | Manual | Five minutes on the mixed pair: no visible stutter, no input focus theft |

**Definition of done:**

- Initial thresholds: at least 58 fps average per window over a 60 s run, p99 frame time at or under 20 ms; on failure the fallback decision (separate processes, or engine-level investigation) is taken here, not later.
- Thresholds recorded before the first run; any later relaxation logged in `test-reports` with a reason.

### 6.2 v0.1 — Two Seats, Two Monitors, Two Gamepads

The first milestone turns the spike into framework code: seat manager, input router, display mapper and one shared 3D world with two camera windows. Gamepads only - the router refuses keyboard events by test (MS-IN-003), keeping the platform limitation of Section 8 visible in the codebase itself rather than in a design document nobody re-reads.

**Table 6:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-CORE-001 | L1 | create_seat returns unique sequential ids |
| MS-CORE-002 | L1 | Session state machine: idle, configured, running, ended; legal transitions only |
| MS-DISP-001 | L1 | assign_display validates against the injected screen inventory |
| MS-DISP-002 | L1 | Two seats cannot claim the same display |
| MS-IN-001 | L1 | Joypad events route by device id |
| MS-IN-002 | L1 | Events from unassigned devices return no seat and are counted |
| MS-IN-003 | L1 | Keyboard events are refused for every seat |
| MS-IN-004 | L2 | Device disconnect marks the seat controller-lost; reconnect restores it |
| MS-CORE-003 | L2 | Boot: two windows on assigned screens, both cameras in the shared world |
| MS-MAN-002 | Manual | Gamepad hot-plug during play recovers without fault |

**Definition of done:**

- All L1 and L2 tests green in the pr pipeline on the baseline Godot version.
- MS-BENCH-001 re-run on the candidate build and recorded; two humans complete a five-minute duel on two monitors with independent cameras, episode recorded.

### 6.3 v0.2 — Four Seats and Automatic Display Assignment

Scaling to four seats stresses the display mapper and the render budget. Auto-assignment maps seats to unclaimed screens, and the four-window benchmark measures what four independent viewports really cost on the target GPU - including the per-viewport shadow atlas overhead that makes four views dearer than the naive four-times-the-pixels estimate.

**Table 7:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-DISP-003 | L1 | Auto-assignment maps N seats onto N distinct screens; defined failure when fewer |
| MS-CORE-004 | L1 | Session refuses to start while a seat has no display binding |
| MS-BENCH-003 | L3 | Four 1080p windows: frame-time distribution at default quality |
| MS-MAN-003 | Manual | Four players: HUDs and camera views correctly paired across windows |

**Definition of done:**

- Four-window benchmark recorded; if 60 fps is not met at default quality, per-seat quality scaling is pulled forward from v0.4 as a design input.
- A monitor unplugged mid-session demotes the seat cleanly instead of crashing.

### 6.4 v0.3 — Privacy Layer and Per-Seat Interfaces

Competitive play requires that each seat sees only what it may see: private maps, inventories, team channels. The privacy layer is a pure filter over replication data, which makes it almost entirely L1-testable. Audio is investigated but deliberately parked: Godot exposes one process-global audio output device, so per-seat headphones require a GDExtension speaking to the OS audio APIs - scheduled only after the privacy core, and starting with a capability probe rather than a feature.

**Table 8:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-PRIV-001 | L1 | Entities flagged hidden-for-seat excluded from that seat's replication set |
| MS-PRIV-002 | L1 | HUD channels isolated; seat A inventory absent from seat B snapshot |
| MS-PRIV-003 | L1 | Team-only communication routes only to seats on that team |
| MS-PRIV-004 | L2 | Hidden information absent from the wire format, not just invisible in the UI |
| MS-CORE-005 | L1 | Pause and settings scope follows the declared policy (seat-local vs session-wide) |

**Definition of done:**

- Privacy tests run against serialized snapshots, proving isolation at the data level.
- Audio capability probe (MS-CORE-006, exploratory) documents GDExtension requirements before any audio milestone is scheduled.

### 6.5 v0.4 — Profiling and Per-Seat Quality Scaling

Four views at full quality will exceed many single-GPU budgets, so quality becomes per-seat and measurable: shadow atlas size, MSAA and render scale are seat inputs. The benchmark verifies that scaling actually recovers the frame budget, which turns the GPU-cost risk (R4) into a managed dial rather than a discovery.

**Table 9:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-BENCH-004 | L3 | Four windows: quality profile mid restores p99 under threshold |
| MS-BENCH-005 | L3 | Quality change mid-session: no window loss or seat reassignment |
| MS-DISP-004 | L1 | Quality profiles validate against a schema; invalid values rejected |

**Definition of done:**

- Benchmark history committed as a CSV trend showing the quality-to-frame-time curve for the reference GPU.
- MS-BENCH-002 re-run on the mixed-refresh pair after quality changes.

### 6.6 v1.0 — API Freeze and Reusable Extension

Version 1.0 is a documentation and contract milestone: the public API is frozen and the contract suite becomes the enforcement mechanism - from here, breaking changes require a deprecation cycle. The example game demonstrates every framework capability, and the contributor guide ships in-repo.

**Table 10:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-CORE-010 | L1 | API conformance: every documented method and error path exercised |
| MS-CORE-011 | L2 | Fresh-project smoke test: blank project plus addon creates two seats and boots |
| MS-MAN-005 | Manual | Two-hour soak: four players, hot-plug events, one quality change, no restart |

**Definition of done:**

- All pipelines green on the release candidate; all manual episodes re-run and recorded on that exact build.
- Every public symbol in the conformance suite appears in the API reference and `docs/testing.md`.

### 6.7 Streaming Phase 1 — Dedicated Server

Streaming starts with the conventional architecture: a headless authoritative server, clients rendering locally. Godot supports headless dedicated servers, and the critical new test asset is determinism - the same seed plus the same scripted inputs must produce the same world state hash, because every later streaming and rollback feature depends on it.

**Table 11:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-NET-001 | L2 | Headless server boots; two clients connect, join seats, receive snapshots |
| MS-NET-002 | L2 | Determinism: fixed seed plus scripted inputs yield identical state hashes |
| MS-NET-003 | L2 | Reconnect within the grace window restores the seat and its private state |
| MS-NET-004 | L2 | Snapshot deltas correct; bandwidth bounded under an action storm |
| MS-IN-005 | L2 | Remote input feeds the same seat action interface as local input |

**Definition of done:**

- Loopback integration suite runs headless in the pr pipeline.
- One L4 soak: server plus two real clients over wired LAN for one hour, logs uploaded.

### 6.8 Streaming Phase 2 — Single Streamed Player

One seat stops rendering locally: the server renders an additional per-seat camera, encodes it, and a client decodes and displays it while sending input back. A headless server does not render, so the streaming runtime is a separate rendering-capable build. Latency budgets are initial working targets to be validated, not promises: motion-to-photon within 80 ms on wired LAN for co-op, 50 ms as the stretch goal for competitive modes.

**Table 12:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-STR-001 | L3 | Per-seat capture produces frames that differ between two seats' cameras |
| MS-STR-002 | L3 | Stream decodes on the reference client; motion-to-photon within budget at 1080p60 |
| MS-STR-003 | L2 | Streamed seat input routes identically to local input |
| MS-MAN-004 | Manual | Perceptual latency: player judges responsiveness blind, wired vs Wi-Fi |

**Definition of done:**

- Latency measurement method documented (timestamps at input, tick, encode, decode, present) with CSV evidence.
- Per-stream bandwidth assumption recorded (order of 10-25 Mbps for 1080p60, confirmed on target hardware).

### 6.9 Streaming Phase 3 — Independent Multi-Stream Sessions

Multiple simultaneous per-player streams must be independent: stream A's input must never affect stream B's view. Encoder capacity must be measured rather than assumed, because concurrent hardware-encoder session limits vary by GPU generation and driver; the probe reports the achievable session count on the reference hardware instead of asserting a number.

**Table 13:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-STR-004 | L3 | Two concurrent 1080p60 streams hold frame budget and latency budget |
| MS-STR-005 | L3 | Encoder probe: maximum stable simultaneous streams, reported as CSV |
| MS-STR-006 | L2 | Cross-stream isolation: input on stream A never affects seat B |
| MS-PRIV-005 | L2 | Stream content respects the privacy layer: hidden entities absent from frames |

**Definition of done:**

- Isolation tests include an adversarial scripted client that attempts to subscribe to another seat's stream (rejected by test).
- Concurrency probe results recorded for the reference GPU; scaling guidance written into docs.

### 6.10 Streaming Phase 4 — Hybrid Sessions

The final phase mixes locally rendering and server-streamed seats in one match - the architecture principle being that the simulation does not care where a player's screen is rendered. Fairness is the test focus: no seat may be structurally disadvantaged by its rendering path, within declared tolerances.

**Table 14:** New tests introduced

| Test id | Layer | Verifies |
| --- | --- | --- |
| MS-STR-007 | L2 | Local and streamed seats observe the same state within one tick |
| MS-STR-008 | L4 | Fairness soak: streamed vs local round-trip latency measured and bounded |
| MS-NET-005 | L2 | Seat migration: streamed seat converts to local rendering, state preserved |

**Definition of done:**

- Hybrid soak executed with the full L4 rig; results recorded and published with the release.
- Latency budget table for all seat types (local, streamed, migrated) documented in docs.

## 7. Traceability Matrix

The matrix ties each engine system to the layers and identifiers that verify it and to the milestone that introduces it. It is the checkpoint used at milestone exit and release: a row with an empty cell is unfinished work, and a test id that cannot be placed in a row is scope creep - and because the matrix changes only through pull requests that change tests, it stays honest.

**Table 15:** Engine systems mapped to verification

| Engine system | L1 / L2 verification | L3 / L4 / manual verification | Introduced |
| --- | --- | --- | --- |
| Multi-seat manager and session | MS-CORE-001, 002, 004, 005 | MS-MAN-005 soak | v0.1 |
| Display compositor | MS-DISP-001, 002, 003 | MS-BENCH-001 to 003, MS-DISP-004 (L3 window placement) | v0.1 / v0.2 |
| Input isolation | MS-IN-001 to 005 | MS-MAN-002 hot-plug episode | v0.1 |
| Shared simulation | MS-NET-002 determinism | MS-BENCH-003 four-view load | v0.1 |
| Privacy and fairness layer | MS-PRIV-001 to 005 | MS-MAN-003 HUD pairing episode | v0.3 (seeded v0.1) |
| Dedicated-server netcode | MS-NET-001, 003, 004 | L4 LAN soak | Phase 1 |
| Streaming pipeline | MS-STR-003, 006 | MS-STR-001, 002, 004, 005, MS-MAN-004 | Phases 2-3 |
| Hybrid orchestration | MS-STR-007, MS-NET-005 (migration) | MS-STR-008 fairness soak | Phase 4 |
| Docs and examples | MS-CORE-010 conformance, 011 smoke | Fresh-clone walkthrough at release | v1.0 |

## 8. Risk-Based Test Priorities

Test effort follows risk, and this register is the sequencing argument for the whole plan. R1 to R8 were known from platform research before the first commit; R9 joined from implementation experience when the runner's zero-test exit code surfaced. Each is paired with the verification that either retires it or escalates it. The escalation rule repeats the fork corollary of Section 2: an engine-level workaround or fork becomes discussable only when the paired check has actually failed on target hardware and the evidence sits in `test-reports`.

**Table 16:** Risk register with verification pairing

| Id | Risk | Priority | Verification and contingency |
| --- | --- | --- | --- |
| R1 | Multi-window vsync misbehaves across monitors (open Godot issues exist for mixed refresh rates) | Critical | Milestone 0 spike, MS-BENCH-001/002 before any framework code; failure triggers the fallback architecture decision |
| R2 | Stock Godot cannot isolate multiple keyboards and mice (device index shared with first controller) | High | MS-IN-003 refuses keyboards in v0.1; GDExtension raw-input design only after v1.0, with its own probe test |
| R3 | Per-seat audio needs OS-level routing (one global output device in Godot) | Medium | Parked beyond v0.3; MS-CORE-006 capability probe precedes any implementation |
| R4 | Four-view GPU cost exceeds single-GPU budget (per-viewport shadow atlases) | High | MS-BENCH-003 measurement at v0.2; MS-BENCH-004 quality scaling as the managed response |
| R5 | Streaming motion-to-photon latency too high for competitive play | High | MS-STR-002 measurement against declared budgets; competitive modes scoped out if the budget is missed |
| R6 | Headless server cannot render; streaming needs a separate rendering runtime | Medium | Architecture constraint accepted; Phase 2 build matrix includes the rendering runtime from day one |
| R7 | Hardware encoder concurrency limits vary by GPU and driver | Medium | MS-STR-005 probe measures instead of assuming; guidance published per reference GPU |
| R8 | Wi-Fi bandwidth and jitter break streamed seats in real homes | Medium | MS-MAN-004 blind perceptual episode wired vs Wi-Fi; docs declare a wired LAN requirement if warranted |
| R9 | Test runner exits 0 when no test cases are discovered, so a broken suite or a mistyped path reports green | High | Wrapper `test/run_tests.sh` enforces per-suite discovery on every direct invocation; the pr pipeline cross-checks the action's JUnit report for every `*_test.gd` suite; the first live CI run confirmed the report location (15 November 2026) |

Priorities translate directly into test order: R1 is why the spike is milestone zero, R2 is why the input router refuses keyboards by contract, and R4 is why quality scaling is designed in v0.4 while its measurement starts at v0.2. R9 is why every CI invocation must prove it discovered the suites it claims to have run. Any new risk enters this table through a pull request, under the same evidence rule - R9 itself arrived that way, with the failing scenarios attached.

## 9. Hardware Test Protocol: Automated and Manual

### 9.1 Automated Benchmark Scenes

Track A of the two-track strategy automates everything a GPU and two displays can verify without a human. The benchmark scene places the load of a real session - N windows, shared world, moving actors - and logs per-frame delta times per window to CSV. A small analysis script turns each CSV into the statistics the thresholds use: mean fps, p50, p95 and p99 frame time, and a stutter count (frames exceeding 1.5 times the refresh interval). The same scene runs locally for developers and on the nightly self-hosted runner, so numbers stay comparable.

**Listing 6:** Frame-time capture for the benchmark scenes

```gdscript
# test/bench/bench_frame_pacing.gd (excerpt)
extends Node

const BENCH_SECONDS := 60.0
var _elapsed := 0.0
var _frames: Array[float] = []

func _ready() -> void:
    for child in get_tree().root.get_children():
        if child is Window:
            child.vsync_mode = DisplayServer.VSYNC_ENABLED

func _process(delta: float) -> void:
    _frames.append(delta)
    _elapsed += delta
    if _elapsed >= BENCH_SECONDS:
        _write_csv()
        get_tree().quit()
```

The analysis script (`analyze_frame_times.py`) is plain Python with no Godot dependency, reads the CSV, applies the threshold table and exits non-zero on failure so CI can gate on it. Thresholds are declared per scenario; the initial values come from the milestone 0 definition: at least 58 fps average per window and p99 frame time at or under 20 ms for two-window scenarios at 1080p.

The repository also carries a rig-day runbook, `docs/rig_day.md`, which sequences the milestone 0 evidence run end to end - both monitor-pair captures, the analyzer gates, the MS-MAN-001 episode and the same-day fallback decision - under the standing rule that evidence captures always run at full duration: the flag that shortens a benchmark exists for smoke tests only.

### 9.2 Manual Episodes and Checklists

Manual does not mean informal. Every manual check is an **episode**: a numbered MS-MAN identifier, a precondition list, a fixed procedure, and pass criteria written before the run. Episodes run on milestone and release candidates, and the filled checklist - including build hash, hardware, date and verdict - is committed to `test-reports/`. The full catalogue lives in `docs/testing.md`; Appendix B shows the format. Two episodes are mandatory before any milestone exit: the perceptual stutter check on a mixed-refresh pair, and the gamepad hot-plug episode.

**Table 17:** Core manual episodes

| Episode | Question it answers | Cadence |
| --- | --- | --- |
| MS-MAN-001 | Is the mixed-refresh pair visibly stable during five minutes of play? | Milestone 0, every milestone exit |
| MS-MAN-002 | Does controller hot-plug during play recover without fault? | v0.1 onward |
| MS-MAN-003 | Are HUDs, cameras and private information correctly paired per window? | v0.2, v0.3 |
| MS-MAN-004 | Does streamed play feel responsive, wired and Wi-Fi, judged blind? | Phases 2-4 |
| MS-MAN-005 | Does a long living-room session survive hot-plug, quality changes, no restart? | v1.0 RC, releases |

### 9.3 Recording and Trending Results

Every automated benchmark run leaves a CSV artifact; every manual episode leaves a filled checklist; both land in `test-reports/` under a directory named for the build hash, which gives the project its performance history for free. The nightly pipeline posts a trend summary (mean and p99 per scenario over the last thirty runs) to the maintainers channel, so regressions appear as slopes rather than surprises at release time. A regression is defined quantitatively: a scenario whose p99 worsens by more than 15 percent across five consecutive nightly runs opens an issue automatically.

## 10. Contributor Guide and Quality Gates

### 10.1 Running the Tests Locally

Contributors install gdUnit4 from the Godot Asset Library or vendor it from the repository, then run suites from the editor's gdUnit4 context menu or the command-line runner documented in the gdUnit4 README. Complete, current instructions - including the Godot version baseline and editor settings - live in `docs/testing.md`, and a fresh clone that cannot run `test/unit` green within ten minutes is treated as a documentation bug. Benchmark scenes require a machine with a display and are never required for ordinary pull requests.

### 10.2 Writing Tests That Survive

Conventions are few and enforceable in review. Each test asserts one behaviour and is named for it, carries its MS identifier in the comment above it, and uses gdUnit4 assertion families rather than bare conditionals, so failures read as sentences. **No wall-clock sleeps**: waiting for time to pass is a determinism bug; wait for conditions or inject time through the seam of Section 5.3. Flaky tests are quarantined within one week of their first failure - moved to a quarantine directory with an open issue - and a quarantined test either becomes deterministic or is deleted within a milestone; a permanently flaky test is worse than no test, because it teaches the team to ignore red.

### 10.3 Definition of Done and Release Gates

Two levels of done apply. A **pull request** is done when the pr pipeline is green, the new or changed behaviour is covered by tests with identifiers, and no threshold regression appears if benchmark-relevant code changed. A **milestone** is done when its section 6 exit criteria hold: automated tests green in the required pipelines, listed episodes recorded with pass verdicts, and the traceability matrix row for any newly introduced system complete. The v1.0 release additionally requires the full matrix - pr, nightly, soak - green on the release candidate, all manual episodes re-run on that exact build, and the contributor guide reviewed against the shipped API. Four standing rules summarise the gates: red before green, evidence over assertion, one test framework, contract tests over internals - each elaborated in Sections 2, 4 and 8.

## 11. Conclusions and Immediate Next Steps

This plan is executable as written: every layer, identifier, pipeline and threshold needed to start is defined, and the two open platform risks are converted into scheduled measurements rather than worries. The sequencing is deliberate - the frame-pacing spike precedes the framework because its failure would change the architecture; the privacy layer precedes audio because it is fully testable headless; streaming starts with the conventional dedicated-server phase because it reuses the strongest existing Godot capability. The plan is a living document: each milestone exit updates the traceability matrix, the risk register and, where evidence demands it, the thresholds - always through pull requests with the evidence attached.

The first three actions, in order:

1. Stand up the repository skeleton of Section 4.2 with the pr pipeline, so every later contribution lands inside the quality system from the first commit.
2. Write MS-CORE-001 and MS-DISP-001 as red tests against a deliberately empty addon, establishing the red-green-refactor rhythm on day one.
3. Build the benchmark scene and run milestone 0 on the available hardware, recording MS-BENCH-001 and MS-BENCH-002 against the thresholds declared in Section 6.1 - before writing any seat, window or gameplay code.

From there the roadmap of Section 6 proceeds milestone by milestone, each with its tests already named.

## Appendix A: Reference gdUnit4 Test Suite

The listings below collect the v0.1 reference suite in one place, including the privacy filter suite that arrives in v0.3, so a new contributor sees the target style immediately. Stub classes live in the test directory; they subclass the framework seams rather than depending on any mocking library.

**Listing 7:** Privacy filter suite (v0.3 scope, style reference)

```gdscript
# test/unit/privacy_filter_test.gd
class_name PrivacyFilterTest
extends GdUnitTestSuite

# MS-PRIV-001: entities flagged hidden for a seat are excluded
# from that seat's replication set.
func test_hidden_entities_are_not_replicated() -> void:
    var filter := VisibilityFilter.new()
    var enemy := {
        "id": 7,
        "team": "red",
        "hidden_for": [1],
    }
    assert_that(filter.visible_to(enemy, 0)).is_true()
    assert_that(filter.visible_to(enemy, 1)).is_false()

# MS-PRIV-002: per-seat data channels stay isolated; seat A's
# inventory is absent from seat B's snapshot.
func test_seat_snapshots_are_isolated() -> void:
    var session := Session.new()
    var a := session.create_seat()
    var b := session.create_seat()
    a.set_private("inventory", {"items": ["sword"]})
    assert_that(b.snapshot().has("inventory")).is_false()
```

**Listing 8:** InputRouter implementation (green step for Listing 5)

```gdscript
# addons/multiseat/input/input_router.gd
# the green step for Listing 5
class_name InputRouter
extends RefCounted

var _device_to_seat := {}

func assign_device(seat_id: int, device_id: int) -> void:
    _device_to_seat[device_id] = seat_id

func route(event: InputEvent) -> int:
    if event is InputEventJoypadButton \
            or event is InputEventJoypadMotion:
        return _device_to_seat.get(event.device, -1)
    return -1   # keyboards and mice are refused in v0.1
```

**Listing 9:** The screen inventory stub used by L1 tests

```gdscript
# test/unit/screen_inventory_stub.gd
class_name ScreenInventoryStub
extends ScreenInventory

var _screens: Array

func _init(screens: Array) -> void:
    _screens = screens

func has_screen(id: int) -> bool:
    return _screens.has(id)

func screen_count() -> int:
    return _screens.size()
```

Together with the seat manager and input router suites of Section 5, these files are the seed of `test/unit`; milestone sections of Section 6 name every test that joins them.

## Appendix B: Sample Manual Test Episode Checklist

Episodes are recorded as filled checklists committed to `test-reports/`. The template below shows the two mandatory episodes in their filled-in form; verdicts shown are examples of the recording format, not claims about hardware that has not yet been tested.

**Table 18:** Episode MS-MAN-001: dual-display perceptual check

| Field | Entry |
| --- | --- |
| Build | git hash of the milestone candidate, Godot version, renderer (Forward+) |
| Hardware | GPU model, two monitors with refresh rates (e.g., 144 Hz + 60 Hz), connection types |
| Preconditions | Release build; both monitors connected; both gamepads paired; no other GPU load |
| Procedure | Start the two-seat scene; play for five minutes; alternate window focus deliberately; unplug and replug one gamepad once |
| Pass criteria | No visible stutter on either display; no input delivered to the wrong seat after focus changes; hot-plug recovers |
| Verdict | PASS or FAIL, tester name, date, notes; on FAIL attach the benchmark CSV of the same run |

**Table 19:** Episode MS-MAN-004: streamed-play perceptual latency check

| Field | Entry |
| --- | --- |
| Build | Server and client git hashes, encoder settings (codec, bitrate, resolution) |
| Hardware | Server GPU, client device (Steam Deck or PC), link type: wired LAN and Wi-Fi, run separately |
| Preconditions | Phase 2 scene running; local seat active as control; streamed seat under test |
| Procedure | Tester plays the streamed seat blind to link type for three minutes per run; rates responsiveness 1-5; run repeated once per link type |
| Pass criteria | Wired run rated 4 or higher and no missed-input reports; Wi-Fi result recorded even when failing, to inform documentation |
| Verdict | PASS or FAIL per link type, tester name, date; attach the latency CSV from MS-STR-002 |
