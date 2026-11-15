# The composed two-seat benchmark scene (plan Sections 6.1, 9.1) — the
# artifact the entire hardware day runs on: MS-BENCH-001/002 captures,
# the MS-MAN-001 perceptual episode and the v0.1 duel. Two seats, two
# borderless windows on the assigned screens, two cameras over one
# shared World3D with moving actors, and joypad input routed to each
# seat's pawn — so the spike measures its own question instead of an
# empty process loop.
#
# Capture, CSV writing and the ++ user arguments are inherited from
# bench_frame_pacing.gd; this script only builds the load. The screen
# inventory is injectable so the headless structural suite
# (bench_scene_test.gd) can stub it; on the rig the real adapter answers
# and DisplayCompositor's placement path finally runs against real
# screens. With fewer screens than seats, boot degrades honestly: bound
# seats only, and the CSV records what actually rendered.
extends "res://test/bench/bench_frame_pacing.gd"

const SEAT_COUNT := 2
const ACTOR_COUNT := 24

var screen_inventory: ScreenInventory

var session: Session
var windows: Array[Window] = []
var pawns := {}

var _actors: Array[MeshInstance3D] = []
var _world_root: Node3D
var _t := 0.0

func _ready() -> void:
	_build_session()
	_build_world()
	# Vsync is forced here on the windows this scene created: the
	# inherited loop only inspects direct children of the tree root,
	# which these never are (they sit under this node). The dummy
	# display server of a headless run rejects the assignment outright,
	# so it applies on real display servers only.
	if DisplayServer.get_name() != "headless":
		for window in windows:
			window.vsync_mode = DisplayServer.VSYNC_ENABLED
	super._ready()   # reads user arguments, then captures every frame

func _process(delta: float) -> void:
	_t += delta
	for i in _actors.size():
		var phase := _t * (0.5 + 0.1 * float(i)) + float(i)
		_actors[i].position = Vector3(
			sin(phase) * 3.0,
			1.0 + sin(phase * 1.7) * 0.5,
			cos(phase * 0.8) * 3.0)
	super._process(delta)   # frame capture

# Routes a joypad event to the owning seat's pawn; returns the seat id.
# _unhandled_input uses it on the rig; the structural suite drives it
# headless so the wiring is a contract, not a hope. Routing goes through
# the session's router - the same instance assign_device populated -
# never a parallel one.
func route_input(event: InputEvent) -> int:
	var seat_id := session.input_router.route(event)
	if seat_id < 0 or not pawns.has(seat_id):
		return seat_id
	var motion := event as InputEventJoypadMotion
	if motion == null:
		return seat_id
	var pawn: Node3D = pawns[seat_id]
	match motion.axis:
		JOY_AXIS_LEFT_X:
			pawn.position.x += motion.axis_value * 0.2
		JOY_AXIS_LEFT_Y:
			pawn.position.z += motion.axis_value * 0.2
	return seat_id

func _unhandled_input(event: InputEvent) -> void:
	route_input(event)

func _build_session() -> void:
	session = Session.new()
	if screen_inventory == null:
		screen_inventory = ScreenInventory.new()   # the real adapter
	session.screen_inventory = screen_inventory
	var screen := 0
	for i in SEAT_COUNT:
		var seat := session.create_seat()
		session.assign_device(seat.id, i)   # seat i owns joypad i
		if session.assign_display(seat.id, screen):
			screen += 1
	var compositor := DisplayCompositor.new()
	windows = compositor.boot(session)
	for window in windows:
		add_child(window)
	_place_cameras()

# Cameras take two fixed, distinct viewpoints on the shared cluster —
# the two views the mixed-refresh pair must pace identically.
func _place_cameras() -> void:
	for i in windows.size():
		var camera := _camera_of(windows[i])
		if camera == null:
			continue
		var angle := float(i) * PI / 2.0
		camera.position = Vector3(cos(angle) * 8.0, 4.0, sin(angle) * 8.0)
		camera.look_at(Vector3.ZERO)

# World content lives under the first window's viewport; the shared
# World3D scenario makes it visible from every window's camera.
func _build_world() -> void:
	if windows.is_empty():
		push_warning("bench_two_seat: no screens bound - no world to render, capture records an empty loop")
		return
	_world_root = Node3D.new()
	windows[0].add_child(_world_root)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	_world_root.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	floor_mesh.mesh = plane
	_world_root.add_child(floor_mesh)
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.55, 0.6)
	for i in ACTOR_COUNT:
		var actor := MeshInstance3D.new()
		actor.mesh = box
		actor.material_override = material
		_world_root.add_child(actor)
		_actors.append(actor)
	for i in SEAT_COUNT:
		var pawn := MeshInstance3D.new()
		var pawn_mesh := BoxMesh.new()
		pawn_mesh.size = Vector3(1.0, 1.0, 1.0)
		pawn.mesh = pawn_mesh
		var pawn_material := StandardMaterial3D.new()
		pawn_material.albedo_color = Color.RED if i == 0 else Color.BLUE
		pawn.material_override = pawn_material
		pawn.position = Vector3(-2.0 + 4.0 * float(i), 0.5, 0.0)
		_world_root.add_child(pawn)
		pawns[i] = pawn

func _camera_of(window: Window) -> Camera3D:
	for child in window.get_children():
		if child is Camera3D:
			return child
	return null
