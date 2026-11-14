# Session state machine contract tests (plan Section 6.2, MS-CORE-002).
class_name SessionTest
extends GdUnitTestSuite

# MS-CORE-002: the session walks idle -> configured -> running -> ended
# and refuses every illegal transition.
func test_session_walks_legal_transitions_in_order() -> void:
	var session := Session.new()
	assert_int(session.state).is_equal(Session.State.IDLE)
	assert_that(session.configure()).is_true()
	assert_int(session.state).is_equal(Session.State.CONFIGURED)
	assert_that(session.start()).is_true()
	assert_int(session.state).is_equal(Session.State.RUNNING)
	assert_that(session.end()).is_true()
	assert_int(session.state).is_equal(Session.State.ENDED)

# MS-CORE-002: illegal transitions return false and leave the state alone.
func test_session_refuses_illegal_transitions() -> void:
	var session := Session.new()
	assert_that(session.start()).is_false()        # idle -> running
	assert_int(session.state).is_equal(Session.State.IDLE)
	assert_that(session.end()).is_false()          # idle -> ended
	assert_that(session.configure()).is_true()
	assert_that(session.configure()).is_false()    # configure twice
	assert_that(session.end()).is_false()          # configured -> ended
	assert_int(session.state).is_equal(Session.State.CONFIGURED)
	assert_that(session.start()).is_true()
	assert_that(session.configure()).is_false()    # running -> configured
	assert_that(session.start()).is_false()        # start twice
	assert_int(session.state).is_equal(Session.State.RUNNING)
