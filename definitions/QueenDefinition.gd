extends Resource
class_name QueenDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

@export var base_max_hp: int = 100
@export var base_move_speed: float = 180.0

@export var starting_weapon_id: String = ""

@export_file("*.tscn") var visual_scene_path: String = ""
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and visual_scene_path.strip_edges() != ""
	)
