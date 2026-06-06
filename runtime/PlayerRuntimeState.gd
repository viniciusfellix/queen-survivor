extends Resource
class_name PlayerRuntimeState

@export var queen_id: String = "gaia"

@export var max_hp: int = 100

@export var current_hp: int = 100

@export var defense_percent: float = 0.0

@export var move_speed: float = 180.0

var move_direction: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var last_valid_aim_direction: Vector2 = Vector2.RIGHT
var facing_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_animation_time_scale: float = 1.0
var is_alive: bool = true
var current_gameplay_state: String = GameplayStateTypes.IDLE
var current_visual_state: String = GameplayStateTypes.IDLE
var total_damage_taken: int = 0
var last_damage_taken: int = 0
var last_damage_source_id: String = ""
var death_cause: String = ""
var coin_magnet_radius_multiplier: float = 1.0
var coin_collect_radius_multiplier: float = 1.0
var is_invincible: bool = false
var invincibility_timer: float = 0.0

func setup_from_queen_definition(definition: QueenDefinition) -> void:
	queen_id = definition.id
	max_hp = definition.base_max_hp
	current_hp = max_hp
	move_speed = definition.base_move_speed

func set_gameplay_state(new_state: String) -> void:
	if current_gameplay_state == new_state:
		return

	current_gameplay_state = new_state

func apply_input(move: Vector2, aim: Vector2) -> void:
	if not is_alive:
		move_direction = Vector2.ZERO
		_update_aim_direction(aim)
		set_gameplay_state(GameplayStateTypes.DEAD)
		return

	if is_dashing:
		_update_aim_direction(aim)
		_update_visual_facing_from_movement(dash_direction)
		set_gameplay_state(GameplayStateTypes.DASHING)
		return

	move_direction = move

	_update_aim_direction(aim)
	_update_visual_facing_from_movement(move_direction)
	_update_movement_state()

func start_dash(
	direction: Vector2,
	aim: Vector2,
	animation_time_scale: float = 1.0
) -> void:
	if not is_alive:
		return

	if direction.length() <= 0.001:
		return

	is_dashing = true
	dash_direction = direction.normalized()
	dash_animation_time_scale = max(0.01, animation_time_scale)
	move_direction = dash_direction
	is_moving = true

	_update_aim_direction(aim)
	_update_visual_facing_from_movement(dash_direction)
	set_gameplay_state(GameplayStateTypes.DASHING)

func update_dash(
	direction: Vector2,
	aim: Vector2,
	animation_time_scale: float = 1.0
) -> void:
	if not is_alive:
		return

	if direction.length() > 0.001:
		dash_direction = direction.normalized()

	dash_animation_time_scale = max(0.01, animation_time_scale)
	move_direction = dash_direction
	is_moving = true

	_update_aim_direction(aim)
	_update_visual_facing_from_movement(dash_direction)
	set_gameplay_state(GameplayStateTypes.DASHING)

func finish_dash(move: Vector2, aim: Vector2) -> void:
	is_dashing = false
	dash_direction = Vector2.ZERO
	dash_animation_time_scale = 1.0

	apply_input(move, aim)
	
func apply_damage(final_damage: int, source_id: String = "") -> void:
	if not is_alive:
		return

	if final_damage <= 0:
		return

	current_hp = max(0, current_hp - final_damage)

	last_damage_taken = final_damage
	total_damage_taken += final_damage
	last_damage_source_id = source_id

	if current_hp <= 0:
		kill(source_id)

func kill(source_id: String = "") -> void:
	if not is_alive:
		return

	is_alive = false
	current_hp = 0
	death_cause = source_id

	move_direction = Vector2.ZERO
	is_moving = false

	is_dashing = false
	dash_direction = Vector2.ZERO
	dash_animation_time_scale = 1.0
	
	set_gameplay_state(GameplayStateTypes.DEAD)

func heal(amount: int) -> void:
	if amount <= 0:
		return

	if not is_alive:
		return

	current_hp = min(max_hp, current_hp + amount)

func _update_aim_direction(aim: Vector2) -> void:
	if aim.length() > 0.001:
		aim_direction = aim.normalized()
		last_valid_aim_direction = aim_direction
	else:
		aim_direction = last_valid_aim_direction

func _update_visual_facing_from_movement(move: Vector2) -> void:
	if abs(move.x) <= 0.001:
		return

	if move.x < 0.0:
		facing_direction = Vector2.LEFT
	else:
		facing_direction = Vector2.RIGHT

func _update_movement_state() -> void:
	is_moving = move_direction.length() > 0.001

	if not is_alive:
		set_gameplay_state(GameplayStateTypes.DEAD)
	elif is_moving:
		set_gameplay_state(GameplayStateTypes.MOVING)
	else:
		set_gameplay_state(GameplayStateTypes.IDLE)
