extends Resource
class_name QueenDefinition

@export var id: String = ""

@export var display_name_key: String = ""

@export var description_key: String = ""

@export_group("Base Attributes")

@export var base_max_hp: int = 100

@export var base_move_speed: float = 180.0

@export_group("Starting Equipment")

@export var starting_weapon_id: String = ""

@export_group("Hurtbox")

@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")

@export_file("*.tscn") var visual_scene_path: String = ""

@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

@export_group("Dash")

@export var dash_definition: QueenDashDefinition

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and visual_scene_path.strip_edges() != ""
	)

func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false
