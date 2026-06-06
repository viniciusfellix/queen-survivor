extends Resource
class_name SpawnTimelineEntryDefinition

@export var id: String = ""

@export var start_time_seconds: float = 0.0

@export var end_time_seconds: float = 60.0

@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

@export var enemy_definition: EnemyDefinition

@export var spawn_interval_seconds: float = 2.2

@export var max_alive_enemies: int = 12

@export var spawn_min_distance: float = 420.0

@export var spawn_max_distance: float = 620.0

@export var spawn_on_activate: bool = true

func is_valid_entry() -> bool:
	return (
		id.strip_edges() != ""
		and end_time_seconds > start_time_seconds
		and spawn_interval_seconds > 0.0
		and max_alive_enemies > 0
		and enemy_scene_path.strip_edges() != ""
		and enemy_definition != null
	)

func is_active_at(elapsed_seconds: float) -> bool:
	return elapsed_seconds >= start_time_seconds and elapsed_seconds < end_time_seconds
