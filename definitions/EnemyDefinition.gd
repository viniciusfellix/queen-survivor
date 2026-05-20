extends Resource
class_name EnemyDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var base_max_hp: int = 10
@export var base_move_speed: float = 90.0

# Dano de contato.
@export var contact_damage: int = 5
@export var contact_damage_radius: float = 32.0
@export var contact_damage_interval_seconds: float = 1.0
@export var contact_damage_type: String = DamageTypes.PHYSICAL

# Fraquezas e resistências.
@export var weak_damage_types: PackedStringArray = []
@export var resistant_damage_types: PackedStringArray = []

@export var weakness_bonus_percent: float = 50.0
@export var resistance_reduction_percent: float = 50.0

# XP futura.
@export var xp_reward: int = 1

# Moeda futura.
@export var coin_drop_chance: float = 0.25
@export var coin_drop_value: int = 1

# Visual real opcional.
@export_file("*.tscn") var visual_scene_path: String = ""
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

# Placeholder/debug visual.
@export var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)
@export var debug_radius: float = 18.0

func is_valid_definition() -> bool:
	return id.strip_edges() != ""

func is_weak_to_damage_type(damage_type: String) -> bool:
	return weak_damage_types.has(damage_type)

func is_resistant_to_damage_type(damage_type: String) -> bool:
	return resistant_damage_types.has(damage_type)
