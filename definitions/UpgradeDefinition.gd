extends Resource
class_name UpgradeDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var upgrade_type: String = ""

# Valor inteiro, usado para HP flat, dano flat etc.
@export var value_int: int = 0

# Valor decimal/percentual, usado para velocidade %, cooldown % etc.
@export var value_float: float = 0.0

# Futuro: para limitar stack por run.
@export var max_stack_in_run: int = 999

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and upgrade_type.strip_edges() != ""
	)
