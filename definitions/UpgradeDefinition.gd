extends Resource
class_name UpgradeDefinition

@export var id: String = ""

@export var display_name_key: String = ""

@export var description_key: String = ""

@export var icon: Texture2D

@export var upgrade_type: String = ""

@export var value_int: int = 0

@export var value_float: float = 0.0

@export var max_stack_in_run: int = 999

@export var show_level_badge: bool = true

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and upgrade_type.strip_edges() != ""
	)
