extends Resource
class_name UpgradePoolDefinition

@export var id: String = ""
@export var display_name_key: String = ""

# Regra oficial atual:
# começa com 3 opções.
# Futuramente upgrades globais podem aumentar para 4 e 5.
@export var option_count: int = 3

@export var upgrades: Array[UpgradeDefinition] = []

# Tenta evitar que as mesmas opções apareçam no level-up imediatamente seguinte.
@export var avoid_last_offered_options: bool = true

# Se a pool válida estiver pequena demais, permite repetir opções.
@export var allow_repeat_when_valid_pool_is_small: bool = true

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and option_count > 0 and not upgrades.is_empty()

func get_valid_upgrades(selected_counts: Dictionary = {}) -> Array[UpgradeDefinition]:
	var valid_upgrades: Array[UpgradeDefinition] = []

	for upgrade: UpgradeDefinition in upgrades:
		if upgrade == null:
			continue

		if not upgrade.is_valid_definition():
			continue

		if not _upgrade_has_stack_available(upgrade, selected_counts):
			continue

		valid_upgrades.append(upgrade)

	return valid_upgrades

func get_debug_summary() -> String:
	var ids: Array[String] = []

	for upgrade: UpgradeDefinition in upgrades:
		if upgrade == null:
			continue

		ids.append(upgrade.id)

	return "%s options=%s upgrades=%s" % [
		id,
		str(option_count),
		", ".join(ids)
	]

func _upgrade_has_stack_available(upgrade: UpgradeDefinition, selected_counts: Dictionary) -> bool:
	if upgrade == null:
		return false

	if upgrade.max_stack_in_run <= 0:
		return false

	var current_count: int = int(selected_counts.get(upgrade.id, 0))

	return current_count < upgrade.max_stack_in_run
