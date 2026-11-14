# Privacy layer (plan Listing 7): a pure filter over replication data, so
# it is fully L1-testable — hidden information is excluded from the data a
# seat receives, not merely painted over in its UI.
class_name VisibilityFilter
extends RefCounted

func visible_to(entity: Dictionary, seat_id: int) -> bool:
	var hidden_for: Array = entity.get("hidden_for", [])
	return not hidden_for.has(seat_id)
