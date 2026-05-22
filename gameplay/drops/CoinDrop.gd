extends Node2D
class_name CoinDrop

@export var coin_definition: CoinDropDefinition

@export var value: int = 1

@export var player_group_name: String = "player"

@export var magnet_radius: float = 150.0
@export var collect_radius: float = 24.0
@export var initial_idle_seconds: float = 0.15

@export var magnet_acceleration: float = 900.0
@export var max_magnet_speed: float = 520.0

@export var draw_debug_visual: bool = true
@export var debug_radius: float = 8.0
@export var debug_color: Color = Color(1.0, 0.78, 0.18, 1.0)
@export var debug_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)

var player_node: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var elapsed_seconds: float = 0.0
var is_collected: bool = false
var is_magnetized: bool = false
var collection_enabled: bool = true

func _ready() -> void:
	_apply_definition()
	player_node = _resolve_player()
	queue_redraw()
	
	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	elapsed_seconds += delta
	
	if not collection_enabled:
		return

	if RunQuery.is_run_finished(get_tree()):
		return

	if player_node == null:
		player_node = _resolve_player()

	if player_node == null:
		return

	var distance_to_player: float = global_position.distance_to(player_node.global_position)
	var effective_collect_radius: float = _get_effective_collect_radius()
	var effective_magnet_radius: float = _get_effective_magnet_radius()

	if distance_to_player <= effective_collect_radius:
		_collect()
		return

	if elapsed_seconds < initial_idle_seconds:
		return

	if distance_to_player <= effective_magnet_radius:
		is_magnetized = true
		_update_magnet_movement(delta)
	else:
		is_magnetized = false
		velocity = velocity.move_toward(Vector2.ZERO, magnet_acceleration * delta)

	global_position += velocity * delta
	queue_redraw()

func _draw() -> void:
	if not draw_debug_visual:
		return

	draw_circle(Vector2.ZERO, debug_radius, debug_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, debug_outline_color, 2.0)

	if is_magnetized:
		draw_arc(Vector2.ZERO, _get_effective_magnet_radius(), 0.0, TAU, 48, Color(1.0, 0.9, 0.2, 0.18), 1.0)

func setup(p_definition: CoinDropDefinition, p_value: int = 1, p_player: Node2D = null) -> void:
	coin_definition = p_definition
	value = max(1, p_value)

	if p_player != null:
		player_node = p_player

	_apply_definition()
	queue_redraw()

func _apply_definition() -> void:
	if coin_definition == null:
		return

	value = max(1, value)

	magnet_radius = coin_definition.magnet_radius
	collect_radius = coin_definition.collect_radius
	initial_idle_seconds = coin_definition.initial_idle_seconds
	magnet_acceleration = coin_definition.magnet_acceleration
	max_magnet_speed = coin_definition.max_magnet_speed
	debug_radius = coin_definition.debug_radius
	debug_color = coin_definition.debug_color
	debug_outline_color = coin_definition.debug_outline_color

func _update_magnet_movement(delta: float) -> void:
	var to_player: Vector2 = player_node.global_position - global_position

	if to_player.length() <= 0.001:
		return

	var desired_velocity: Vector2 = to_player.normalized() * max_magnet_speed
	velocity = velocity.move_toward(desired_velocity, magnet_acceleration * delta)

func _collect() -> void:
	if not collection_enabled:
		return

	if RunQuery.is_run_finished(get_tree()):
		return
		
	if is_collected:
		return

	is_collected = true

	GameEvents.run_coin_collected.emit(value, global_position)
	GameEvents.emit_debug("[CoinDrop] Moeda coletada: value=%s pos=%s" % [
		str(value),
		str(global_position)
	])

	queue_free()

func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

func _on_run_finished(_result_payload: RunResultPayload) -> void:
	collection_enabled = false
	is_magnetized = false
	velocity = Vector2.ZERO
	queue_redraw()

func _get_effective_magnet_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_magnet_radius_multiplier")
	return magnet_radius * multiplier

func _get_effective_collect_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_collect_radius_multiplier")
	return collect_radius * multiplier

func _get_player_collection_multiplier(key: String) -> float:
	if player_node == null:
		return 1.0

	if not player_node.has_method("get_drop_collection_modifiers"):
		return 1.0

	var modifiers_variant: Variant = player_node.call("get_drop_collection_modifiers")

	if not (modifiers_variant is Dictionary):
		return 1.0

	var modifiers: Dictionary = modifiers_variant as Dictionary
	var multiplier: float = float(modifiers.get(key, 1.0))

	return max(0.10, multiplier)
