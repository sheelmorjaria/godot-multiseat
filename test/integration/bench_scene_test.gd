# Structural suite for the composed two-seat benchmark scene (plan
# Sections 6.1, 9.1; MS-BENCH-001/002 structural half). Without this
# scene, rig day measures an empty process loop instead of the two-window
# question the milestone exists to answer — so its existence and load are
# themselves a contract. Pacing stays rig-only (plan Table 2); here we
# assert what a headless runner can see: the load the CSV will be
# recorded against.
class_name BenchSceneTest
extends GdUnitTestSuite

# MS-BENCH-001/002 (structural): the composed scene boots two seats into
# two windows with two cameras over one shared world, one pawn per seat,
# and joypad input routed to the owning seat's pawn.
func test_composed_scene_carries_the_two_seat_load() -> void:
	var scene: Node = load("res://test/bench/bench_two_seat.tscn").instantiate()
	scene.screen_inventory = ScreenInventoryStub.new([0, 1])
	add_child(scene)
	assert_int(scene.windows.size()).is_equal(2)
	var worlds := {}
	for window in scene.windows:
		assert_that(window is Window).is_true()
		assert_that(_camera_of(window)).is_not_null()
		worlds[window.world_3d] = true
	assert_int(worlds.size()).is_equal(1)
	assert_int(scene.pawns.size()).is_equal(2)

	var before0: Vector3 = scene.pawns[0].position
	var before1: Vector3 = scene.pawns[1].position
	var event := InputEventJoypadMotion.new()
	event.device = 1
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = 1.0
	assert_int(scene.route_input(event)).is_equal(1)
	assert_float(scene.pawns[1].position.x).is_greater(before1.x)
	assert_vector(scene.pawns[0].position).is_equal(before0)
	scene.free()   # subtree (windows, actors, pawns) freed with it

func _camera_of(window: Window) -> Camera3D:
	for child in window.get_children():
		if child is Camera3D:
			return child
	return null
