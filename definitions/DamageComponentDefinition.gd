extends Resource
class_name DamageComponentDefinition

@export var damage_type: String = DamageTypes.PHYSICAL
@export var amount: int = 1

# Futuro:
# Pode ser usado para componentes que não sofrem bônus de fraqueza.
@export var affected_by_weakness: bool = true

# Futuro:
# Pode ser usado para componentes que ignoram resistência.
@export var affected_by_resistance: bool = true

func is_valid_component() -> bool:
	return amount > 0 and damage_type.strip_edges() != ""
