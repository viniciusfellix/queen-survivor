extends Resource
class_name WeaponDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var max_level: int = 10

# Cooldown inicial aproximado oficial da Gaia.
@export var cooldown_seconds: float = 2.0

# Visual do ataque.
@export var attack_visual_offset: float = 86.0
@export var attack_visual_lifetime: float = 0.22
@export_file("*.tscn") var attack_visual_scene_path: String = ""

# Hitbox do ataque.
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"
@export var attack_hitbox_offset: float = 86.0
@export var attack_hitbox_radius: float = 72.0
@export var attack_hitbox_lifetime: float = 0.12

# Modelo novo oficial: lista de componentes.
@export var damage_components: Array[DamageComponentDefinition] = []

# Fallback temporário para compatibilidade.
@export var base_damage: int = 5
@export var damage_type: String = DamageTypes.PHYSICAL

func is_valid_definition() -> bool:
	return id.strip_edges() != ""

func has_damage_components() -> bool:
	return not damage_components.is_empty()
