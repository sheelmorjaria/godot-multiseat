# Seam over DisplayServer screen queries (plan Section 5.3). Nothing in the
# framework may call DisplayServer screen functions directly: the runtime
# adapter answers here, a stub answers in CI (ScreenInventoryStub).
class_name ScreenInventory
extends RefCounted

func has_screen(id: int) -> bool:
	return id >= 0 and id < DisplayServer.get_screen_count()

func screen_count() -> int:
	return DisplayServer.get_screen_count()
