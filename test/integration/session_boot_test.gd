# Session boot integration tests (plan Section 6.2, MS-CORE-003).
# The boot contract is structural: one window per display-bound seat,
# a camera per window, all windows sharing one World3D. Physical
# placement on a real monitor is L3 per plan Table 2 — the L2 test
# asserts the compositor's placement intent, never the OS.
class_name SessionBootTest
extends GdUnitTestSuite

# MS-CORE-003: boot creates one window per seat, each with a camera in
# the shared world, placement intent equal to the seat bindings.
func test_boot_creates_one_window_per_seat_sharing_one_world() -> void:
	var session := Session.new()
	session.screen_inventory = ScreenInventoryStub.new([0, 1])
	var compositor := DisplayCompositor.new()
	var a := session.create_seat()
	var b := session.create_seat()
	assert_that(session.assign_display(a.id, 0)).is_true()
	assert_that(session.assign_display(b.id, 1)).is_true()
	var windows := compositor.boot(session)
	for window in windows:
		auto_free(window)
	assert_int(windows.size()).is_equal(2)
	assert_int(compositor.screen_for(windows[0])).is_equal(0)
	assert_int(compositor.screen_for(windows[1])).is_equal(1)
	var worlds := {}
	for window in windows:
		assert_that(window is Window).is_true()
		assert_that(_camera_of(window)).is_not_null()
		worlds[window.world_3d] = true
	assert_int(worlds.size()).is_equal(1)

# A window outside the scene tree never activates its camera, so the
# structural check reads the camera child directly.
func _camera_of(window: Window) -> Camera3D:
	for child in window.get_children():
		if child is Camera3D:
			return child
	return null

# MS-CORE-003: seats without a display binding get no window — boot maps
# bound seats only, so an unbound seat cannot steal a screen.
func test_boot_skips_seats_without_display_binding() -> void:
	var session := Session.new()
	session.screen_inventory = ScreenInventoryStub.new([0])
	var compositor := DisplayCompositor.new()
	var bound := session.create_seat()
	var unbound := session.create_seat()
	assert_that(session.assign_display(bound.id, 0)).is_true()
	var windows := compositor.boot(session)
	for window in windows:
		auto_free(window)
	assert_int(windows.size()).is_equal(1)
	assert_int(compositor.screen_for(windows[0])).is_equal(0)
