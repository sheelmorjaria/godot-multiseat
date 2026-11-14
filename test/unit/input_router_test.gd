# InputRouter contract tests (plan Listing 5).
class_name InputRouterTest
extends GdUnitTestSuite

# MS-IN-001: joypad events route by device id, not window focus.
func test_joypad_events_route_by_device_id() -> void:
	var router := InputRouter.new()
	router.assign_device(0, 0)   # seat 0 owns joypad 0
	router.assign_device(1, 1)   # seat 1 owns joypad 1
	var motion := InputEventJoypadMotion.new()
	motion.device = 1
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	assert_int(router.route(motion)).is_equal(1)
	var button := InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	assert_int(router.route(button)).is_equal(0)

# MS-IN-002: events from unassigned devices return no seat and are counted.
func test_unassigned_device_events_return_no_seat_and_are_counted() -> void:
	var router := InputRouter.new()
	router.assign_device(0, 0)
	var event := InputEventJoypadMotion.new()
	event.device = 5   # no seat ever claimed joypad 5
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = 1.0
	assert_int(router.route(event)).is_equal(-1)
	assert_int(router.route(event)).is_equal(-1)
	assert_int(router.unassigned_event_count).is_equal(2)

# MS-IN-003: stock Godot cannot isolate keyboards, so v0.1
# actively refuses keyboard input instead of mis-routing it.
func test_keyboard_events_are_refused() -> void:
	var router := InputRouter.new()
	router.assign_device(0, 0)
	var event := InputEventKey.new()
	event.device = 0
	assert_int(router.route(event)).is_equal(-1)
