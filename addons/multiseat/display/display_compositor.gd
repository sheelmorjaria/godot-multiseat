# The v0.1 boot (MS-CORE-003): one borderless Window per display-bound
# seat, a camera per window, all windows sharing one World3D — the
# single-process two-window architecture Milestone 0 exists to validate.
# Physical placement on a real monitor is L3 (plan Table 2): placement is
# attempted against the OS screen count and the intent is recorded here,
# but the L2 suite asserts the intent, never the compositor's report.
class_name DisplayCompositor
extends RefCounted

var _screen_by_window := {}

func boot(session: Session) -> Array[Window]:
	var world := World3D.new()
	var windows: Array[Window] = []
	for seat in session.seats():
		if seat.display_id < 0:
			continue
		var window := Window.new()
		window.borderless = true
		window.world_3d = world
		window.add_child(Camera3D.new())
		if seat.display_id < DisplayServer.get_screen_count():
			window.current_screen = seat.display_id
		_screen_by_window[window.get_instance_id()] = seat.display_id
		windows.append(window)
	return windows

# Placement intent for a window this compositor booted; -1 otherwise.
func screen_for(window: Window) -> int:
	return _screen_by_window.get(window.get_instance_id(), -1)
