# Seat lifecycle and id assignment (MS-CORE-001). Display claims delegate
# to DisplayMapper since the plan Section 5.1 refactor; the tests of
# Listing 3 run unchanged across it, which is the point of contract tests.
class_name SeatManager
extends RefCounted

var screen_inventory: ScreenInventory:
	set(inventory):
		screen_inventory = inventory
		_display_mapper.screen_inventory = inventory

var _next_id := 0
var _seats := {}
var _display_mapper := DisplayMapper.new()

func create_seat() -> Seat:
	var seat := Seat.new(_next_id)
	_next_id += 1
	_seats[seat.id] = seat
	return seat

func seats() -> Array:
	return _seats.values()

func get_seat(seat_id: int) -> Seat:
	return _seats.get(seat_id)

func assign_display(seat_id: int, screen: int) -> bool:
	if not _display_mapper.claim(seat_id, screen):
		return false
	_seats[seat_id].display_id = screen
	return true
