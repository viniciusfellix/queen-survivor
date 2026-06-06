extends Resource
class_name EnemyDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export_group("Base Attributes")
@export var base_max_hp: int = 10
@export var base_move_speed: float = 90.0
@export_group("Attacks")
@export var contact_attack: EnemyAttackDefinition

@export_group("Weaknesses and Resistances")
@export var weak_damage_types: PackedStringArray = []
@export var resistant_damage_types: PackedStringArray = []
@export var weakness_bonus_percent: float = 50.0
@export var resistance_reduction_percent: float = 50.0

@export_group("Rewards")
@export var xp_reward: int = 1
@export var coin_drop_chance: float = 0.25
@export var coin_drop_value: int = 1

@export_group("Hurtbox")
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")
@export_file("*.tscn") var visual_scene_path: String = ""
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""
@export_group("Debug Placeholder")
@export var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)
@export var debug_radius: float = 18.0

@export_group("Body Bump")
@export var body_bump_enabled: bool = true
@export var body_bump_power: float = 2.0
@export var body_bump_velocity_per_power: float = 24.0
@export var body_bump_max_velocity: float = 140.0
@export var body_bump_decay_per_second: float = 280.0
@export_range(0.0, 1.0, 0.05) var body_bump_lateral_influence: float = 0.35

@export_group("Player Body Slide")
@export var player_body_slide_enabled: bool = true
@export var player_body_slide_power: float = 2.0
@export var player_body_slide_velocity_per_power: float = 36.0
@export var player_body_slide_max_velocity: float = 160.0
@export var player_body_slide_decay_per_second: float = 360.0
@export_range(0.0, 1.0, 0.05)
var player_body_slide_away_influence: float = 0.30

@export_group("Received Knockback")
@export var received_knockback_multiplier: float = 1.0
@export var received_knockback_max_velocity: float = 520.0
@export var received_knockback_decay_per_second: float = 1800.0
@export_range(0.0, 1.0, 0.05) var received_knockback_chase_weight: float = 0.15


func is_valid_definition() -> bool:
	return id.strip_edges() != ""

func has_valid_contact_attack() -> bool:
	return contact_attack != null and contact_attack.is_valid_definition()

func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false

func is_weak_to_damage_type(damage_type: String) -> bool:
	return weak_damage_types.has(damage_type)

func is_resistant_to_damage_type(damage_type: String) -> bool:
	return resistant_damage_types.has(damage_type)
