# Green step for plan Listing 3 (MS-CORE-001, MS-DISP-001, MS-DISP-002).
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
