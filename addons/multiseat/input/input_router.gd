# Green step for plan Listing 5 (MS-IN-001, MS-IN-002, MS-IN-003).
class_name InputRouter
extends RefCounted

# MS-IN-002: joypad events from devices no seat owns are counted so
# mis-assignment shows up in diagnostics instead of silently vanishing.
var unassigned_event_count := 0

var _device_to_seat := {}

func assign_device(seat_id: int, device_id: int) -> void:
	_device_to_seat[device_id] = seat_id

func route(event: InputEvent) -> int:
	if event is InputEventJoypadButton \
			or event is InputEventJoypadMotion:
		if _device_to_seat.has(event.device):
			return _device_to_seat[event.device]
		unassigned_event_count += 1
		return -1
	return -1   # keyboards and mice are refused in v0.1
