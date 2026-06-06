extends Resource
class_name EnemyAttackDefinition

@export var id: String = ""

@export_group("Damage")

@export var raw_damage: int = 1

@export var damage_type: String = DamageTypes.PHYSICAL

@export var can_be_reduced_by_defense: bool = true

@export_group("Timing")

@export var hit_interval_seconds: float = 1.0

@export var start_delay_seconds: float = 0.75

@export_group("Attack Areas")

@export var attack_areas: Array[AttackAreaDefinition] = []

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and raw_damage > 0
		and DamageTypes.is_valid_type(damage_type)
		and hit_interval_seconds > 0.0
		and start_delay_seconds >= 0.0
		and has_valid_attack_areas()
	)

func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

func build_damage_payload(
	source_node: Node,
	source_id: String
) -> DamagePayload:
	var payload: DamagePayload = DamagePayload.new(
		raw_damage,
		damage_type,
		source_node,
		source_id,
		id
	)

	payload.can_be_reduced_by_defense = (
		can_be_reduced_by_defense
		and damage_type != DamageTypes.TRUE_DAMAGE
	)

	return payload

func get_areas_debug_summary() -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		summaries.append(attack_area.get_debug_summary())

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
