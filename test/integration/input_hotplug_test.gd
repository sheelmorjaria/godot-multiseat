# Joypad hot-plug integration tests (plan Section 6.2, MS-IN-004).
# The real joy_connection_changed signal never fires headless, so the
# episode drives the session's own notification API — the scripted-input
# pattern the plan's L2 layer defines. The hardware layer of the same
# behaviour is MS-MAN-002.
class_name InputHotplugTest
extends GdUnitTestSuite

# MS-IN-004: device disconnect marks the seat controller-lost;
# reconnect restores it.
func test_disconnect_marks_seat_controller_lost_and_reconnect_restores() -> void:
	var session := Session.new()
	var seat := session.create_seat()
	session.assign_device(seat.id, 0)
	assert_bool(seat.controller_lost).is_false()
	session.notify_joypad_connection(0, false)
	assert_bool(seat.controller_lost).is_true()
	session.notify_joypad_connection(0, true)
	assert_bool(seat.controller_lost).is_false()

# MS-IN-004: connection events for unknown devices are a no-op, not a
# fault — spurious events must not take the session down with them.
func test_connection_events_for_unknown_devices_are_ignored() -> void:
	var session := Session.new()
	var seat := session.create_seat()
	session.assign_device(seat.id, 0)
	session.notify_joypad_connection(7, false)
	assert_bool(seat.controller_lost).is_false()
