extends "res://tests/TestCase.gd"


func get_suite_name() -> String:
	return "RewardResolver"


func run() -> Array[Dictionary]:
	return [
		run_case(
			"victory_applies_multiplier_and_bonus",
			Callable(self, "_test_victory_applies_multiplier_and_bonus")
		),
		run_case(
			"defeat_returns_collected_coins_only",
			Callable(self, "_test_defeat_returns_collected_coins_only")
		),
		run_case(
			"negative_inputs_are_safely_clamped",
			Callable(self, "_test_negative_inputs_are_safely_clamped")
		)
	]


func _test_victory_applies_multiplier_and_bonus() -> void:
	var result: int = RewardResolver.calculate_final_money_reward(true, 10, 1.5, 3)
	assert_equal(result, 18)


func _test_defeat_returns_collected_coins_only() -> void:
	var result: int = RewardResolver.calculate_final_money_reward(false, 12, 3.0, 99)
	assert_equal(result, 12)


func _test_negative_inputs_are_safely_clamped() -> void:
	var result: int = RewardResolver.calculate_final_money_reward(true, -5, 2.0, -10)
	assert_equal(result, 0)
