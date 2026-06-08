extends "res://tests/TestCase.gd"


func get_suite_name() -> String:
	return "DamageResolver"


func run() -> Array[Dictionary]:
	return [
		run_case(
			"base_damage_applies_on_neutral_enemy",
			Callable(self, "_test_base_damage_applies_on_neutral_enemy")
		),
		run_case(
			"physical_component_applies_only_on_weakness",
			Callable(self, "_test_physical_component_applies_only_on_weakness")
		),
		run_case(
			"resistance_does_not_reduce_base_damage",
			Callable(self, "_test_resistance_does_not_reduce_base_damage")
		),
		run_case(
			"multiple_weakness_components_stack_as_bonus",
			Callable(self, "_test_multiple_weakness_components_stack_as_bonus")
		),
		run_case(
			"breakdown_reports_base_weakness_resistant_and_neutral",
			Callable(self, "_test_breakdown_reports_base_weakness_resistant_and_neutral")
		)
	]


func _test_base_damage_applies_on_neutral_enemy() -> void:
	var enemy := _make_enemy_definition([], [])
	var payload := _make_payload(
		6,
		[
			_make_component(DamageTypes.PHYSICAL, 3),
			_make_component(DamageTypes.MAGICAL, 3)
		]
	)

	var result: Dictionary = DamageResolver.calculate_enemy_damage(payload, enemy)

	assert_equal(
		result.get("raw_total"),
		12,
		"raw_total should preserve the full payload before conditional application."
	)
	assert_equal(result.get("final_total"), 6, "Defense-free neutral target should keep base damage.")


func _test_physical_component_applies_only_on_weakness() -> void:
	var enemy := _make_enemy_definition([DamageTypes.PHYSICAL], [])
	var payload := _make_payload(6, [_make_component(DamageTypes.PHYSICAL, 3)])

	var result: Dictionary = DamageResolver.calculate_enemy_damage(payload, enemy)

	assert_equal(result.get("raw_total"), 9, "Weakness should add the matching component.")
	assert_equal(result.get("final_total"), 9)


func _test_resistance_does_not_reduce_base_damage() -> void:
	var enemy := _make_enemy_definition([], [DamageTypes.PHYSICAL])
	var payload := _make_payload(6, [_make_component(DamageTypes.PHYSICAL, 3)])

	var result: Dictionary = DamageResolver.calculate_enemy_damage(payload, enemy)

	assert_equal(
		result.get("raw_total"),
		9,
		"raw_total should preserve the full payload even when resistance blocks the bonus."
	)
	assert_equal(result.get("final_total"), 6)


func _test_multiple_weakness_components_stack_as_bonus() -> void:
	var enemy := _make_enemy_definition(
		[DamageTypes.PHYSICAL, DamageTypes.MAGICAL],
		[]
	)
	var payload := _make_payload(
		6,
		[
			_make_component(DamageTypes.PHYSICAL, 3),
			_make_component(DamageTypes.MAGICAL, 3)
		]
	)

	var result: Dictionary = DamageResolver.calculate_enemy_damage(payload, enemy)

	assert_equal(result.get("raw_total"), 12)
	assert_equal(result.get("final_total"), 12)


func _test_breakdown_reports_base_weakness_resistant_and_neutral() -> void:
	var weak_enemy := _make_enemy_definition([DamageTypes.PHYSICAL], [])
	var resistant_enemy := _make_enemy_definition([], [DamageTypes.PHYSICAL])
	var neutral_enemy := _make_enemy_definition([], [])
	var weak_payload := _make_payload(6, [_make_component(DamageTypes.PHYSICAL, 3)])
	var resistant_payload := _make_payload(6, [_make_component(DamageTypes.PHYSICAL, 3)])
	var neutral_payload := _make_payload(6, [_make_component(DamageTypes.PHYSICAL, 3)])

	var weak_result: Dictionary = DamageResolver.calculate_enemy_damage(weak_payload, weak_enemy)
	var resistant_result: Dictionary = DamageResolver.calculate_enemy_damage(resistant_payload, resistant_enemy)
	var neutral_result: Dictionary = DamageResolver.calculate_enemy_damage(neutral_payload, neutral_enemy)

	var weak_breakdown: Array = weak_result.get("breakdown", [])
	var resistant_breakdown: Array = resistant_result.get("breakdown", [])
	var neutral_breakdown: Array = neutral_result.get("breakdown", [])

	assert_size(weak_breakdown, 2)
	assert_equal(weak_breakdown[0]["reason"], "base")
	assert_equal(weak_breakdown[1]["reason"], "weakness")
	assert_true(weak_breakdown[1]["applied"])

	assert_size(resistant_breakdown, 2)
	assert_equal(resistant_breakdown[1]["reason"], "resistant")
	assert_false(resistant_breakdown[1]["applied"])

	assert_size(neutral_breakdown, 2)
	assert_equal(neutral_breakdown[1]["reason"], "neutral")
	assert_false(neutral_breakdown[1]["applied"])


func _make_payload(base_damage: int, components: Array[DamageComponentDefinition]) -> DamagePayload:
	var payload := DamagePayload.new(base_damage, DamageTypes.PHYSICAL, null)
	payload.set_components(components)
	return payload


func _make_component(damage_type: String, amount: int) -> DamageComponentDefinition:
	var component := DamageComponentDefinition.new()
	component.damage_type = damage_type
	component.amount = amount
	return component


func _make_enemy_definition(
	weaknesses: Array[String],
	resistances: Array[String]
) -> EnemyDefinition:
	var enemy := EnemyDefinition.new()
	enemy.id = "test_enemy"
	enemy.display_name_key = "enemy.test"
	enemy.base_max_hp = 10
	enemy.weak_damage_types = PackedStringArray(weaknesses)
	enemy.resistant_damage_types = PackedStringArray(resistances)
	return enemy
