extends Resource
class_name UpgradeDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var icon: Texture2D

@export var upgrade_type: String = ""

# Valor inteiro, usado para HP flat, dano flat etc.
@export var value_int: int = 0

# Valor decimal/percentual, usado para velocidade %, cooldown % etc.
@export var value_float: float = 0.0

# Limite de vezes que esse upgrade pode ser escolhido na run.
@export var max_stack_in_run: int = 999

# Futuro: alguns upgrades podem ser consumíveis e não "níveis".
# Por enquanto todos podem exibir Nv. X.
@export var show_level_badge: bool = true

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and upgrade_type.strip_edges() != ""
	)
