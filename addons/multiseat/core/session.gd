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

var screen_inventory: ScreenInventory:
	set(inventory):
		screen_inventory = inventory
		_seat_manager.screen_inventory = inventory

var input_router := InputRouter.new()

var _seat_manager := SeatManager.new()

func create_seat() -> Seat:
	return _seat_manager.create_seat()

func seats() -> Array:
	return _seat_manager.seats()

func get_seat(seat_id: int) -> Seat:
	return _seat_manager.get_seat(seat_id)

func assign_display(seat_id: int, screen: int) -> bool:
	return _seat_manager.assign_display(seat_id, screen)

func assign_device(seat_id: int, device_id: int) -> void:
	input_router.assign_device(seat_id, device_id)

# MS-IN-004: the session-facing half of the hot-plug contract. The
# runtime caller bridges Input.joy_connection_changed here; the binding
# survives the disconnect so reconnect restores the seat.
func notify_joypad_connection(device_id: int, connected: bool) -> void:
	var seat := get_seat(input_router.seat_for_device(device_id))
	if seat != null:
		seat.controller_lost = not connected

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
