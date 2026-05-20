extends RefCounted
class_name LevelUpOptionService

static func generate_options(upgrade_pool: Array[UpgradeDefinition], option_count: int = 3) -> Array[UpgradeDefinition]:
	var valid_options: Array[UpgradeDefinition] = []

	for upgrade: UpgradeDefinition in upgrade_pool:
		if upgrade == null:
			continue

		if not upgrade.is_valid_definition():
			continue

		valid_options.append(upgrade)

	valid_options.shuffle()

	var result: Array[UpgradeDefinition] = []
	var max_count: int = min(option_count, valid_options.size())

	for index: int in range(max_count):
		result.append(valid_options[index])

	return result
