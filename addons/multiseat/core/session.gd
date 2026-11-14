# Session lifecycle (MS-CORE-002): idle -> configured -> running -> ended,
# legal transitions only. Owns the seat manager so callers never touch
# seats outside a session.
class_name Session
extends RefCounted

enum State { IDLE, CONFIGURED, RUNNING, ENDED }

const _LEGAL_TRANSITIONS := {
	State.IDLE: [State.CONFIGURED],
	State.CONFIGURED: [State.RUNNING],
	State.RUNNING: [State.ENDED],
	State.ENDED: [],
}

var state: State = State.IDLE

var _seat_manager := SeatManager.new()

func create_seat() -> Seat:
	return _seat_manager.create_seat()

func configure() -> bool:
	return _transition(State.CONFIGURED)

func start() -> bool:
	return _transition(State.RUNNING)

func end() -> bool:
	return _transition(State.ENDED)

func _transition(to: State) -> bool:
	if not _LEGAL_TRANSITIONS[state].has(to):
		return false
	state = to
	return true
