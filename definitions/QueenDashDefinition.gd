extends Resource
class_name QueenDashDefinition

@export var id: String = ""

@export_group("Movement")
@export var dash_enabled: bool = true
@export var dash_distance_pixels: float = 180.0
@export var dash_duration_seconds: float = 0.18
@export var dash_cooldown_seconds: float = 1.25

@export_group("Damage Rules")
@export var ignore_damage_while_dashing: bool = true

@export_group("Weapon Rules")
@export var allow_weapon_attacks_while_dashing: bool = false
@export var pause_weapon_cooldown_while_dashing: bool = true
@export var reset_weapon_cooldown_when_dash_starts: bool = false
@export var reset_weapon_cooldown_when_dash_ends: bool = true

@export_group("Impact Knockback")
@export var impact_enabled: bool = true
@export var impact_knockback_pixels: float = 450.0
@export var impact_knockback_duration_seconds: float = 0.20
@export var hit_once_per_enemy: bool = true
@export var impact_source_id: String = "queen_dash"

@export_enum("dash_direction", "away_from_gaia", "corridor")
var impact_direction_mode: String = "corridor"

@export_range(0.0, 1.0, 0.05)
var impact_forward_component: float = 0.15

@export var impact_knockback_max_velocity_override: float = 1600.0

@export_range(-1.0, 1.0, 0.05)
var impact_chase_weight_override: float = 0.0

@export_group("Impact Damage")
@export var impact_damage_enabled: bool = false
@export var impact_raw_damage: int = 0
@export var impact_damage_type: String = DamageTypes.PHYSICAL
@export var impact_damage_components: Array[DamageComponentDefinition] = []

@export_group("Impact Areas")
@export var impact_area_scale_multiplier: float = 1.0
@export var impact_areas: Array[AttackAreaDefinition] = []

@export_group("Visual")
@export var dash_side_animation_name: String = "Dash1_Pose3"
@export var dash_up_animation_name: String = ""
@export var dash_down_animation_name: String = ""
@export_range(0.0, 1.0, 0.05) var dash_vertical_threshold: float = 0.55
@export var dash_animation_source_duration_seconds: float = 3.0
@export var match_animation_speed_to_dash_duration: bool = true
@export var allow_blink_while_dashing: bool = false
@export var dash_blink_animation_name: String = ""

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and dash_duration_seconds > 0.0
		and dash_distance_pixels > 0.0
		and dash_cooldown_seconds >= 0.0
	)

func has_valid_impact_areas() -> bool:
	for impact_area: AttackAreaDefinition in impact_areas:
		if impact_area == null:
			continue

		if impact_area.is_valid_definition():
			return true

	return false

func has_valid_impact_damage() -> bool:
	if impact_damage_components.is_empty():
		return impact_raw_damage > 0 and DamageTypes.is_valid_type(impact_damage_type)

	for component: DamageComponentDefinition in impact_damage_components:
		if component == null:
			continue

		if component.is_valid_component():
			return true

	return false
