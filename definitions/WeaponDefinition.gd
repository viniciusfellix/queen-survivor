extends Resource
class_name WeaponDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var max_level: int = 10

@export var cooldown_seconds: float = 2.0

@export_group("Attack Visual")

@export var attack_visual_offset: float = 86.0

@export var attack_visual_lifetime: float = 0.22

@export_file("*.tscn") var attack_visual_scene_path: String = ""

@export_group("Attack Hitbox")

@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

@export var attack_hitbox_offset: float = 86.0

@export var attack_hitbox_lifetime: float = 0.12

@export var attack_areas: Array[AttackAreaDefinition] = []

@export_group("On Hit Effects")

@export var hit_knockback_enabled: bool = false

@export var hit_knockback_pixels: float = 0.0

@export var hit_knockback_duration_seconds: float = 0.12

@export_group("Damage")

@export var damage_components: Array[DamageComponentDefinition] = []

@export var base_damage: int = 5

@export var damage_type: String = DamageTypes.PHYSICAL

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and has_valid_attack_areas()

func has_damage_components() -> bool:
	return not damage_components.is_empty()

func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

func get_attack_areas_debug_summary(scale_multiplier: float = 1.0) -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if not attack_area.is_valid_definition():
			continue

		summaries.append(attack_area.get_debug_summary(scale_multiplier))

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
