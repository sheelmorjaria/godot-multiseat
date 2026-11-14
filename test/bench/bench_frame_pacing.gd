# Frame-time capture for the L3 benchmark scenes (plan Listing 6, MS-BENCH-001/002).
#
# Run standalone for a capture of the process frame loop:
#   godot --path . res://test/bench/bench_frame_pacing.tscn
# or composed under a real session load (N windows, shared world, moving
# actors — plan Section 9.1), where every child Window is forced to vsync
# and the process delta is recorded each frame.
#
# User arguments after the `++` separator:
#   --csv=<path>          output CSV (user://, res:// or absolute);
#                         default user://frame_times.csv
#   --scenario=<label>    recorded in the filename when --csv is not given
#   --bench-seconds=<s>   run length; default 60.0 (plan Section 6.1). The
#                         override exists for smoke runs, never for evidence.
extends Node

const BENCH_SECONDS := 60.0

var _elapsed := 0.0
var _frames: Array[float] = []

var _limit := BENCH_SECONDS
var _csv_path := "user://frame_times.csv"

func _ready() -> void:
	_read_user_args()
	for child in get_tree().root.get_children():
		if child is Window:
			child.vsync_mode = DisplayServer.VSYNC_ENABLED

func _process(delta: float) -> void:
	_frames.append(delta)
	_elapsed += delta
	if _elapsed >= _limit:
		_write_csv()
		get_tree().quit()

func _read_user_args() -> void:
	var scenario := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--csv="):
			_csv_path = arg.substr("--csv=".length())
		elif arg.begins_with("--scenario="):
			scenario = arg.substr("--scenario=".length())
		elif arg.begins_with("--bench-seconds="):
			_limit = float(arg.substr("--bench-seconds=".length()))
	if not scenario.is_empty() and _csv_path == "user://frame_times.csv":
		_csv_path = "user://frame_times_%s.csv" % scenario

func _write_csv() -> void:
	if _csv_path.is_absolute_path():
		var parent := _csv_path.get_base_dir()
		if not parent.is_empty():
			DirAccess.make_dir_recursive_absolute(parent)
	var file := FileAccess.open(_csv_path, FileAccess.WRITE)
	if file == null:
		push_error("bench: cannot open '%s' for writing (error %d)" % [_csv_path, FileAccess.get_open_error()])
		get_tree().quit(1)
		return
	file.store_line("frame,delta_ms")
	for i in _frames.size():
		file.store_line("%d,%.4f" % [i, _frames[i] * 1000.0])
	file.close()
	var total := 0.0
	for delta in _frames:
		total += delta
	print("bench: wrote %d frames to %s (%.1f s wall, %.1f fps average)" % [
		_frames.size(), ProjectSettings.globalize_path(_csv_path), total,
		_frames.size() / total if total > 0.0 else 0.0,
	])
