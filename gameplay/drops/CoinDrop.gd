## Physical coin drop collected during a run.
##
## Responsibilities:
## - represent a dropped coin in the world;
## - wait a short idle window before magnetism can start;
## - detect the player through native Area2D signals;
## - move toward Gaia only while magnetized;
## - collect on the final pickup area;
## - stop interacting once the run is ending/finished.
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

@onready var magnet_area: Area2D = $MagnetArea
@onready var magnet_collision_shape: CollisionShape2D = $MagnetArea/CollisionShape2D
@onready var collect_area: Area2D = $CollectArea
@onready var collect_collision_shape: CollisionShape2D = $CollectArea/CollisionShape2D
@onready var idle_timer: Timer = $IdleTimer

var player_node: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var is_collected: bool = false
var is_magnetized: bool = false
var collection_enabled: bool = true
var player_inside_magnet_area: bool = false
var player_inside_collect_area: bool = false
var idle_completed: bool = false
var last_applied_magnet_radius: float = -1.0
var last_applied_collect_radius: float = -1.0

## Connects signals and prepares the coin for standalone/runtime use.
func _ready() -> void:
	_connect_area_signals()
	_connect_runtime_signals()
	_activate_coin_runtime()
	_queue_debug_redraw()

## Moves the coin only while magnetized or while decelerating from a previous pull.
func _physics_process(delta: float) -> void:
	if is_collected or not collection_enabled:
		_set_motion_processing_enabled(false)
		return

	if player_node == null or not is_instance_valid(player_node):
		player_node = _resolve_player()

	if player_node == null:
		is_magnetized = false
		velocity = Vector2.ZERO
		_set_motion_processing_enabled(false)
		_queue_debug_redraw()
		return

	if _should_magnetize():
		is_magnetized = true
		_update_magnet_movement(delta)
	else:
		is_magnetized = false
		velocity = velocity.move_toward(Vector2.ZERO, magnet_acceleration * delta)

	if velocity.length() > 0.001:
		global_position += velocity * delta

	if not _should_keep_motion_processing():
		velocity = Vector2.ZERO
		_set_motion_processing_enabled(false)

	_queue_debug_redraw()

## Queues redraw only when debug visuals are enabled.
func _queue_debug_redraw() -> void:
	if draw_debug_visual:
		queue_redraw()

## Draws simple debug visuals for the coin and magnet radius.
func _draw() -> void:
	if not draw_debug_visual:
		return

	draw_circle(Vector2.ZERO, debug_radius, debug_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, debug_outline_color, 2.0)

	if is_magnetized:
		draw_arc(
			Vector2.ZERO,
			_get_effective_magnet_radius(),
			0.0,
			TAU,
			48,
			Color(1.0, 0.9, 0.2, 0.18),
			1.0
		)

## Applies definition, value, and optional player reference at runtime.
func setup(p_definition: CoinDropDefinition, p_value: int = 1, p_player: Node2D = null) -> void:
	coin_definition = p_definition
	value = max(1, p_value)

	if p_player != null:
		player_node = p_player
	elif player_node == null:
		player_node = _resolve_player()

	_activate_coin_runtime()
	_queue_debug_redraw()

## Copies runtime data from the configured CoinDropDefinition.
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

## Connects native Area2D entry/exit signals exactly once.
func _connect_area_signals() -> void:
	if magnet_area != null:
		if not magnet_area.body_entered.is_connected(_on_magnet_area_body_entered):
			magnet_area.body_entered.connect(_on_magnet_area_body_entered)

		if not magnet_area.body_exited.is_connected(_on_magnet_area_body_exited):
			magnet_area.body_exited.connect(_on_magnet_area_body_exited)

	if collect_area != null:
		if not collect_area.body_entered.is_connected(_on_collect_area_body_entered):
			collect_area.body_entered.connect(_on_collect_area_body_entered)

		if not collect_area.body_exited.is_connected(_on_collect_area_body_exited):
			collect_area.body_exited.connect(_on_collect_area_body_exited)

## Connects low-frequency runtime signals used to keep the coin in sync.
func _connect_runtime_signals() -> void:
	if idle_timer != null and not idle_timer.timeout.is_connected(_on_idle_timer_timeout):
		idle_timer.timeout.connect(_on_idle_timer_timeout)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

	if not GameEvents.run_level_up_completed.is_connected(_on_run_level_up_completed):
		GameEvents.run_level_up_completed.connect(_on_run_level_up_completed)

## Refreshes radii from the definition and current player modifiers.
func _refresh_area_radii() -> void:
	var effective_magnet_radius: float = _get_effective_magnet_radius()
	var effective_collect_radius: float = _get_effective_collect_radius()

	if not is_equal_approx(last_applied_magnet_radius, effective_magnet_radius):
		_set_area_radius(magnet_collision_shape, effective_magnet_radius)
		last_applied_magnet_radius = effective_magnet_radius

	if not is_equal_approx(last_applied_collect_radius, effective_collect_radius):
		_set_area_radius(collect_collision_shape, effective_collect_radius)
		last_applied_collect_radius = effective_collect_radius

## Applies a radius safely to a CircleShape2D.
func _set_area_radius(shape_node: CollisionShape2D, radius: float) -> void:
	if shape_node == null:
		return

	var circle_shape: CircleShape2D = shape_node.shape as CircleShape2D

	if circle_shape == null:
		return

	circle_shape.radius = max(1.0, radius)

## One-time overlap sync for spawn/reuse and radius refresh cases.
func _refresh_area_overlap_state_once() -> void:
	player_inside_magnet_area = _area_has_player_body(magnet_area)
	player_inside_collect_area = _area_has_player_body(collect_area)

	if player_inside_collect_area and collection_enabled and not is_collected:
		_collect()

## Checks whether an Area2D currently contains the player body.
func _area_has_player_body(area: Area2D) -> bool:
	if area == null:
		return false

	for body: Node in area.get_overlapping_bodies():
		if _is_valid_player_body(body):
			return true

	return false

## Accelerates the coin toward the player while magnetized.
func _update_magnet_movement(delta: float) -> void:
	var to_player: Vector2 = player_node.global_position - global_position

	if to_player.length() <= 0.001:
		return

	var desired_velocity: Vector2 = to_player.normalized() * max_magnet_speed
	velocity = velocity.move_toward(desired_velocity, magnet_acceleration * delta)

## Collects the coin, emits the event, and returns it to the pool.
func _collect() -> void:
	if not collection_enabled or is_collected:
		return

	is_collected = true
	_stop_idle_window()
	_set_motion_processing_enabled(false)
	_set_coin_active(false)

	GameEvents.run_coin_collected.emit(value, global_position)

	DeveloperAuditLogger.log_spawn(
		"Moeda coletada: value=%s pos=%s" % [
			str(value),
			str(global_position)
		],
		"CoinDrop",
		{
			"value": value,
			"position": global_position
		}
	)

	PoolManager.despawn(self)

## Pool hook: leave the coin inert until setup() reconfigures it.
func _on_pool_acquire() -> void:
	_reset_runtime_state()
	player_node = null
	_stop_idle_window()
	_set_motion_processing_enabled(false)
	_set_coin_active(false)

## Pool hook: disable monitoring/physics and clear transient state.
func _on_pool_release() -> void:
	_reset_runtime_state()
	player_node = null
	_stop_idle_window()
	_set_motion_processing_enabled(false)
	_set_coin_active(false)

## Enables/disables the coin areas and collision shapes.
func _set_coin_active(should_be_active: bool) -> void:
	if magnet_area != null:
		magnet_area.monitoring = should_be_active

	if collect_area != null:
		collect_area.monitoring = should_be_active

	if magnet_collision_shape != null:
		magnet_collision_shape.disabled = not should_be_active

	if collect_collision_shape != null:
		collect_collision_shape.disabled = not should_be_active

## Enables/disables motion processing without affecting the pickup areas.
func _set_motion_processing_enabled(should_be_active: bool) -> void:
	set_physics_process(should_be_active)

## Resolves the first Node2D in the player group.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

## Stops all collection/magnetism when the run ends.
func _on_run_finished(_result_payload: RunResultPayload) -> void:
	collection_enabled = false
	is_magnetized = false
	player_inside_magnet_area = false
	player_inside_collect_area = false
	velocity = Vector2.ZERO
	_stop_idle_window()
	_set_motion_processing_enabled(false)
	_set_coin_active(false)
	_queue_debug_redraw()

## Refreshes radius-dependent state after upgrades are applied.
func _on_run_level_up_completed(_current_level: int, _selected_upgrade_id: String) -> void:
	if is_collected:
		return

	if player_node == null or not is_instance_valid(player_node):
		player_node = _resolve_player()

	_refresh_area_radii()
	_refresh_area_overlap_state_once()
	_reevaluate_motion_state()
	_queue_debug_redraw()

## Returns the effective magnet radius with player modifiers applied.
func _get_effective_magnet_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_magnet_radius_multiplier")
	return magnet_radius * multiplier

## Returns the effective collect radius with player modifiers applied.
func _get_effective_collect_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_collect_radius_multiplier")
	return collect_radius * multiplier

## Reads collection/magnet modifiers from the player when available.
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

## body_entered on MagnetArea: mark player presence and wake motion when needed.
func _on_magnet_area_body_entered(body: Node) -> void:
	if not _is_valid_player_body(body):
		return

	if body is Node2D:
		player_node = body as Node2D

	player_inside_magnet_area = true
	_reevaluate_motion_state()

## body_exited on MagnetArea: stop magnetism once the player leaves the area.
func _on_magnet_area_body_exited(body: Node) -> void:
	if not _is_valid_player_body(body):
		return

	player_inside_magnet_area = false
	_reevaluate_motion_state()

## body_entered on CollectArea: collect immediately when the player touches it.
func _on_collect_area_body_entered(body: Node) -> void:
	if not _is_valid_player_body(body):
		return

	if body is Node2D:
		player_node = body as Node2D

	player_inside_collect_area = true

	if collection_enabled and not is_collected:
		_collect()

## body_exited on CollectArea: keep state in sync for reuse/debug.
func _on_collect_area_body_exited(body: Node) -> void:
	if not _is_valid_player_body(body):
		return

	player_inside_collect_area = false

## Timer timeout: the coin may start magnetizing after the initial idle window.
func _on_idle_timer_timeout() -> void:
	idle_completed = true
	_reevaluate_motion_state()
	_queue_debug_redraw()

## Validates whether a body belongs to the detectable player.
func _is_valid_player_body(body: Node) -> bool:
	if body == null:
		return false

	if player_node != null and body == player_node:
		return true

	return body.is_in_group(player_group_name)

## Rebuilds active state after setup/reuse without starting motion unnecessarily.
func _activate_coin_runtime() -> void:
	_apply_definition()

	if player_node == null or not is_instance_valid(player_node):
		player_node = _resolve_player()

	_reset_runtime_state()
	_refresh_area_radii()
	_set_coin_active(true)
	_refresh_area_overlap_state_once()

	if is_collected:
		return

	_start_idle_window()
	_reevaluate_motion_state()

## Starts or skips the initial idle window.
func _start_idle_window() -> void:
	_stop_idle_window()

	idle_completed = initial_idle_seconds <= 0.0

	if idle_completed:
		return

	if idle_timer == null:
		idle_completed = true
		return

	idle_timer.wait_time = max(0.01, initial_idle_seconds)
	idle_timer.start()

## Stops the idle timer if it is running.
func _stop_idle_window() -> void:
	if idle_timer != null:
		idle_timer.stop()

## Updates whether motion processing should be running right now.
func _reevaluate_motion_state() -> void:
	_set_motion_processing_enabled(_should_keep_motion_processing())

## Returns whether the coin should actively pull toward the player.
func _should_magnetize() -> bool:
	return (
		collection_enabled
		and idle_completed
		and player_inside_magnet_area
		and player_node != null
		and is_instance_valid(player_node)
	)

## Returns whether motion processing still has useful work to do.
func _should_keep_motion_processing() -> bool:
	return _should_magnetize() or velocity.length() > 0.001

## Clears transient runtime state without touching configured definition values.
func _reset_runtime_state() -> void:
	is_collected = false
	is_magnetized = false
	collection_enabled = true
	player_inside_magnet_area = false
	player_inside_collect_area = false
	idle_completed = false
	velocity = Vector2.ZERO
	last_applied_magnet_radius = -1.0
	last_applied_collect_radius = -1.0
