# SeatManager contract tests (plan Listing 3).
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
