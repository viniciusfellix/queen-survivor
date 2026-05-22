extends RefCounted
class_name LevelUpOptionService

static func generate_from_pool(
	upgrade_pool_definition: UpgradePoolDefinition,
	selected_counts: Dictionary = {},
	previous_option_ids: Array[String] = []
) -> Array[UpgradeDefinition]:
	if upgrade_pool_definition == null:
		return []

	if not upgrade_pool_definition.is_valid_definition():
		return []

	var valid_upgrades: Array[UpgradeDefinition] = upgrade_pool_definition.get_valid_upgrades(selected_counts)

	return _generate_from_valid_options(
		valid_upgrades,
		upgrade_pool_definition.option_count,
		selected_counts,
		previous_option_ids,
		upgrade_pool_definition.avoid_last_offered_options,
		upgrade_pool_definition.allow_repeat_when_valid_pool_is_small
	)

static func generate_options(
	upgrade_pool: Array[UpgradeDefinition],
	option_count: int = 3,
	selected_counts: Dictionary = {},
	previous_option_ids: Array[String] = [],
	avoid_last_offered_options: bool = true,
	allow_repeat_when_valid_pool_is_small: bool = true
) -> Array[UpgradeDefinition]:
	var valid_upgrades: Array[UpgradeDefinition] = []

	for upgrade: UpgradeDefinition in upgrade_pool:
		if upgrade == null:
			continue

		if not upgrade.is_valid_definition():
			continue

		if not _upgrade_has_stack_available(upgrade, selected_counts):
			continue

		valid_upgrades.append(upgrade)

	return _generate_from_valid_options(
		valid_upgrades,
		option_count,
		selected_counts,
		previous_option_ids,
		avoid_last_offered_options,
		allow_repeat_when_valid_pool_is_small
	)

static func _generate_from_valid_options(
	valid_upgrades: Array[UpgradeDefinition],
	option_count: int,
	_selected_counts: Dictionary,
	previous_option_ids: Array[String],
	avoid_last_offered_options: bool,
	allow_repeat_when_valid_pool_is_small: bool
) -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []

	if valid_upgrades.is_empty():
		return result

	var safe_option_count: int = max(1, option_count)
	var max_count: int = min(safe_option_count, valid_upgrades.size())

	var preferred_options: Array[UpgradeDefinition] = []

	if avoid_last_offered_options:
		for upgrade: UpgradeDefinition in valid_upgrades:
			if upgrade == null:
				continue

			if previous_option_ids.has(upgrade.id):
				continue

			preferred_options.append(upgrade)
	else:
		preferred_options = valid_upgrades.duplicate()

	preferred_options.shuffle()

	for upgrade: UpgradeDefinition in preferred_options:
		if result.size() >= max_count:
			break

		if upgrade == null:
			continue

		if _result_has_upgrade(result, upgrade.id):
			continue

		result.append(upgrade)

	if result.size() < max_count and allow_repeat_when_valid_pool_is_small:
		var fallback_options: Array[UpgradeDefinition] = valid_upgrades.duplicate()
		fallback_options.shuffle()

		for upgrade: UpgradeDefinition in fallback_options:
			if result.size() >= max_count:
				break

			if upgrade == null:
				continue

			if _result_has_upgrade(result, upgrade.id):
				continue

			result.append(upgrade)

	return result

static func _upgrade_has_stack_available(upgrade: UpgradeDefinition, selected_counts: Dictionary) -> bool:
	if upgrade == null:
		return false

	if upgrade.max_stack_in_run <= 0:
		return false

	var current_count: int = int(selected_counts.get(upgrade.id, 0))

	return current_count < upgrade.max_stack_in_run

static func _result_has_upgrade(result: Array[UpgradeDefinition], upgrade_id: String) -> bool:
	for upgrade: UpgradeDefinition in result:
		if upgrade == null:
			continue

		if upgrade.id == upgrade_id:
			return true

	return false
