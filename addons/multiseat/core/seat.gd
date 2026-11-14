# One player position in a session: owns a display binding and whatever
# private state the privacy layer filters per seat (plan Section 6.4).
class_name Seat
extends RefCounted

var id: int
var display_id := -1

var _private := {}

func _init(seat_id: int) -> void:
	id = seat_id

# MS-PRIV-002: per-seat private channel; only this seat's snapshot sees it.
func set_private(key: String, value) -> void:
	_private[key] = value

func snapshot() -> Dictionary:
	return _private.duplicate(true)
