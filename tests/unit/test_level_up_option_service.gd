extends "res://tests/TestCase.gd"


func get_suite_name() -> String:
	return "LevelUpOptionService"


func run() -> Array[Dictionary]:
	return [
		run_case(
			"returns_expected_number_of_unique_options",
			Callable(self, "_test_returns_expected_number_of_unique_options")
		),
		run_case(
			"respects_stack_limits_from_selected_counts",
			Callable(self, "_test_respects_stack_limits_from_selected_counts")
		),
		run_case(
			"avoids_previous_options_when_pool_allows",
			Callable(self, "_test_avoids_previous_options_when_pool_allows")
		)
	]


func _test_returns_expected_number_of_unique_options() -> void:
	var pool := _make_pool([
		_make_upgrade("u1"),
		_make_upgrade("u2"),
		_make_upgrade("u3"),
		_make_upgrade("u4")
	])

	var options: Array[UpgradeDefinition] = LevelUpOptionService.generate_from_pool(pool)

	assert_size(options, 3)
	assert_equal(_unique_ids(options).size(), 3)


func _test_respects_stack_limits_from_selected_counts() -> void:
	var limited_upgrade := _make_upgrade("limited")
	limited_upgrade.max_stack_in_run = 1

	var pool := _make_pool([
		limited_upgrade,
		_make_upgrade("u2"),
		_make_upgrade("u3")
	])

	var options: Array[UpgradeDefinition] = LevelUpOptionService.generate_from_pool(
		pool,
		{"limited": 1}
	)

	assert_false(_ids(options).has("limited"))


func _test_avoids_previous_options_when_pool_allows() -> void:
	var pool := _make_pool([
		_make_upgrade("u1"),
		_make_upgrade("u2"),
		_make_upgrade("u3"),
		_make_upgrade("u4"),
		_make_upgrade("u5")
	])

	var options: Array[UpgradeDefinition] = LevelUpOptionService.generate_from_pool(
		pool,
		{},
		["u1", "u2"]
	)

	var option_ids: Array[String] = _ids(options)
	assert_false(option_ids.has("u1"))
	assert_false(option_ids.has("u2"))


func _make_pool(upgrades: Array[UpgradeDefinition]) -> UpgradePoolDefinition:
	var pool := UpgradePoolDefinition.new()
	pool.id = "test_pool"
	pool.option_count = 3
	pool.upgrades = upgrades
	pool.avoid_last_offered_options = true
	pool.allow_repeat_when_valid_pool_is_small = true
	return pool


func _make_upgrade(upgrade_id: String) -> UpgradeDefinition:
	var upgrade := UpgradeDefinition.new()
	upgrade.id = upgrade_id
	upgrade.display_name_key = "upgrade.%s.name" % upgrade_id
	upgrade.description_key = "upgrade.%s.description" % upgrade_id
	upgrade.upgrade_type = "flat_damage"
	upgrade.max_stack_in_run = 3
	return upgrade


func _ids(options: Array[UpgradeDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for option: UpgradeDefinition in options:
		if option == null:
			continue
		ids.append(option.id)
	return ids


func _unique_ids(options: Array[UpgradeDefinition]) -> Dictionary:
	var result: Dictionary = {}
	for option: UpgradeDefinition in options:
		if option == null:
			continue
		result[option.id] = true
	return result
