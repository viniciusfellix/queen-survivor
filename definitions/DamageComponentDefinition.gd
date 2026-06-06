extends Resource
class_name DamageComponentDefinition

@export var damage_type: String = DamageTypes.PHYSICAL

@export var amount: int = 1

@export var affected_by_weakness: bool = true

@export var affected_by_resistance: bool = true

func is_valid_component() -> bool:
	return amount > 0 and DamageTypes.is_valid_type(damage_type)
