extends "res://tests/TestCase.gd"


func get_suite_name() -> String:
	return "SpawnTimelineDefinition"


func run() -> Array[Dictionary]:
	return [
		run_case(
			"get_active_entries_returns_multiple_overlapping_waves",
			Callable(self, "_test_get_active_entries_returns_multiple_overlapping_waves")
		),
		run_case(
			"get_active_entry_keeps_latest_start_compatibility",
			Callable(self, "_test_get_active_entry_keeps_latest_start_compatibility")
		),
		run_case(
			"entry_fallbacks_keep_legacy_range_valid",
			Callable(self, "_test_entry_fallbacks_keep_legacy_range_valid")
		),
		run_case(
			"spawn_rule_window_and_tags_work",
			Callable(self, "_test_spawn_rule_window_and_tags_work")
		)
	]


func _test_get_active_entries_returns_multiple_overlapping_waves() -> void:
	var timeline := SpawnTimelineDefinition.new()
	timeline.entries = [
		_make_entry("wave_a", 0.0, 10.0),
		_make_entry("wave_b", 5.0, 15.0)
	]

	var active_entries: Array[SpawnTimelineEntryDefinition] = timeline.get_active_entries(6.0)

	assert_size(active_entries, 2)
	assert_equal(active_entries[0].id, "wave_a")
	assert_equal(active_entries[1].id, "wave_b")


func _test_get_active_entry_keeps_latest_start_compatibility() -> void:
	var timeline := SpawnTimelineDefinition.new()
	timeline.entries = [
		_make_entry("wave_a", 0.0, 10.0),
		_make_entry("wave_b", 5.0, 15.0)
	]

	var active_entry: SpawnTimelineEntryDefinition = timeline.get_active_entry(6.0)

	assert_true(active_entry != null)
	assert_equal(active_entry.id, "wave_b")


func _test_entry_fallbacks_keep_legacy_range_valid() -> void:
	var entry := SpawnTimelineEntryDefinition.new()
	entry.id = "legacy_wave"
	entry.start_time_seconds = 12.0
	entry.end_time_seconds = 24.0
	entry.spawn_interval_seconds = 3.0
	entry.enemy_scene_path = "res://gameplay/enemies/EnemyBase.tscn"
	entry.enemy_definition = _make_enemy_definition("legacy_enemy")

	assert_equal(entry.get_effective_start_time_min_seconds(), 12.0)
	assert_equal(entry.get_effective_start_time_max_seconds(), 12.0)
	assert_equal(entry.get_effective_end_time_min_seconds(), 24.0)
	assert_equal(entry.get_effective_end_time_max_seconds(), 24.0)

	var fallback_rules: Array[SpawnRuleDefinition] = entry.get_effective_spawn_rules()
	assert_size(fallback_rules, 1)
	assert_equal(fallback_rules[0].spawn_interval_min_seconds, 3.0)
	assert_equal(fallback_rules[0].spawn_interval_max_seconds, 3.0)


func _test_spawn_rule_window_and_tags_work() -> void:
	var rule := SpawnRuleDefinition.new()
	rule.id = "elite_rule"
	rule.enemy_scene_path = "res://gameplay/enemies/EnemyBase.tscn"
	rule.enemy_definition = _make_enemy_definition("elite_enemy")
	rule.active_from_seconds = 2.0
	rule.active_until_seconds = 6.0
	rule.tags = PackedStringArray(["elite", "melee"])

	assert_false(rule.is_active_for_wave_elapsed(1.9))
	assert_true(rule.is_active_for_wave_elapsed(3.0))
	assert_false(rule.is_active_for_wave_elapsed(6.0))
	assert_true(rule.has_tag("elite"))
	assert_false(rule.has_tag("boss"))


func _make_entry(entry_id: String, start_seconds: float, end_seconds: float) -> SpawnTimelineEntryDefinition:
	var entry := SpawnTimelineEntryDefinition.new()
	entry.id = entry_id
	entry.start_time_min_seconds = start_seconds
	entry.start_time_max_seconds = start_seconds
	entry.end_time_min_seconds = end_seconds
	entry.end_time_max_seconds = end_seconds
	entry.spawn_rules = [_make_rule("%s_rule" % entry_id)]
	return entry


func _make_rule(rule_id: String) -> SpawnRuleDefinition:
	var rule := SpawnRuleDefinition.new()
	rule.id = rule_id
	rule.enemy_scene_path = "res://gameplay/enemies/EnemyBase.tscn"
	rule.enemy_definition = _make_enemy_definition(rule_id)
	rule.spawn_interval_min_seconds = 2.0
	rule.spawn_interval_max_seconds = 2.0
	return rule


func _make_enemy_definition(enemy_id: String) -> EnemyDefinition:
	var enemy := EnemyDefinition.new()
	enemy.id = enemy_id
	enemy.display_name_key = enemy_id
	enemy.base_max_hp = 5
	return enemy
