# L1 test stub over the ScreenInventory seam (plan Listing 9).
# Deliberately trivial: answers a fixed list, lives in the test directory,
# and adds no mocking dependency — stubs subclass the framework seams.
class_name ScreenInventoryStub
extends ScreenInventory

var _screens: Array

func _init(screens: Array) -> void:
	_screens = screens

func has_screen(id: int) -> bool:
	return _screens.has(id)

func screen_count() -> int:
	return _screens.size()
