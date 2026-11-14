# Owns the screen-claim bookkeeping: validates against the ScreenInventory
# seam and lets a display be owned by at most one seat (MS-DISP-001/002).
# Extracted from SeatManager in the plan Section 5.1 refactor step.
class_name DisplayMapper
extends RefCounted

var screen_inventory: ScreenInventory

var _display_owner := {}

func claim(seat_id: int, screen: int) -> bool:
	if screen_inventory == null:
		return false
	if not screen_inventory.has_screen(screen):
		return false
	if _display_owner.has(screen):
		return false
	_display_owner[screen] = seat_id
	return true
