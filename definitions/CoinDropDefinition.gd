extends Resource
class_name CoinDropDefinition

@export var id: String = "coin_default"

@export var display_name_key: String = "drop.coin.default.name"

@export var default_value: int = 1

@export var magnet_radius: float = 150.0

@export var collect_radius: float = 24.0

@export var initial_idle_seconds: float = 0.15

@export var magnet_acceleration: float = 900.0

@export var max_magnet_speed: float = 520.0

@export var debug_radius: float = 8.0

@export var debug_color: Color = Color(1.0, 0.78, 0.18, 1.0)

@export var debug_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and default_value > 0
