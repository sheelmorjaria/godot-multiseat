# Privacy filter contract tests (plan Listing 7, v0.3 style reference).
class_name PrivacyFilterTest
extends GdUnitTestSuite

# MS-PRIV-001: entities flagged hidden for a seat are excluded
# from that seat's replication set.
func test_hidden_entities_are_not_replicated() -> void:
	var filter := VisibilityFilter.new()
	var enemy := {
		"id": 7,
		"team": "red",
		"hidden_for": [1],
	}
	assert_that(filter.visible_to(enemy, 0)).is_true()
	assert_that(filter.visible_to(enemy, 1)).is_false()

# MS-PRIV-002: per-seat data channels stay isolated; seat A's
# inventory is absent from seat B's snapshot.
func test_seat_snapshots_are_isolated() -> void:
	var session := Session.new()
	var a := session.create_seat()
	var b := session.create_seat()
	a.set_private("inventory", {"items": ["sword"]})
	assert_that(b.snapshot().has("inventory")).is_false()
