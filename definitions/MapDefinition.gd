extends Resource
class_name MapDefinition

@export var id: String = ""

@export var display_name_key: String = ""

@export var description_key: String = ""

@export var duration_seconds: float = 600.0

@export var victory_multiplier: float = 2.0

@export var victory_bonus: int = 0

@export var spawn_timeline: SpawnTimelineDefinition

@export var upgrade_pool: UpgradePoolDefinition

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and duration_seconds > 0.0
