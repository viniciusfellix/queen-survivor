extends "res://tests/TestCase.gd"


func get_suite_name() -> String:
	return "RunState"


func run() -> Array[Dictionary]:
	return [
		run_case(
			"initial_state_is_coherent",
			Callable(self, "_test_initial_state_is_coherent")
		),
		run_case(
			"xp_progression_levels_up_and_carries_remainder",
			Callable(self, "_test_xp_progression_levels_up_and_carries_remainder")
		),
		run_case(
			"coins_and_kills_increment_only_while_active",
			Callable(self, "_test_coins_and_kills_increment_only_while_active")
		),
		run_case(
			"ending_and_result_transitions_lock_state",
			Callable(self, "_test_ending_and_result_transitions_lock_state")
		)
	]


func _test_initial_state_is_coherent() -> void:
	var state := RunState.new()

	assert_equal(state.current_level, 1)
	assert_equal(state.xp_required_for_next_level, 10)
	assert_equal(state.run_coins_collected, 0)
	assert_false(state.is_finished)
	assert_false(state.is_ending)


func _test_xp_progression_levels_up_and_carries_remainder() -> void:
	var state := RunState.new()
	var levels_gained: int = state.add_xp(12)

	assert_equal(levels_gained, 1)
	assert_equal(state.current_level, 2)
	assert_equal(state.current_level_xp, 2)
	assert_equal(state.xp_required_for_next_level, 15)
	assert_equal(state.level_reached, 2)


func _test_coins_and_kills_increment_only_while_active() -> void:
	var state := RunState.new()
	state.add_coins(5)
	state.add_enemy_kill()
	state.mark_victory()
	state.add_coins(10)
	state.add_enemy_kill()

	assert_equal(state.run_coins_collected, 5)
	assert_equal(state.enemies_killed, 1)


func _test_ending_and_result_transitions_lock_state() -> void:
	var state := RunState.new()

	assert_true(state.begin_ending("test"))
	assert_false(state.begin_ending("again"))
	assert_equal(state.death_cause, "test")

	state.mark_defeat("boss")
	assert_true(state.is_finished)
	assert_true(state.is_defeat)
	assert_false(state.is_victory)
	assert_equal(state.result_type, "defeat")
	assert_equal(state.death_cause, "boss")
