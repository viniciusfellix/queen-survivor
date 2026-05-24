extends Node

const DEADZONE: float = 0.25

var move_direction: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var last_valid_aim_direction: Vector2 = Vector2.RIGHT

var using_controller_aim: bool = false
var using_mouse_aim: bool = true

func _ready() -> void:
	_ensure_default_input_actions()

	DeveloperAuditLogger.log_lifecycle(
		"Input inicializado.",
		"InputManager"
	)

func update_input_for_player(player_global_position: Vector2) -> void:
	move_direction = _get_move_direction()
	aim_direction = _get_aim_direction(player_global_position)

	if aim_direction.length() > 0.01:
		last_valid_aim_direction = aim_direction.normalized()
	else:
		aim_direction = last_valid_aim_direction		

func get_move_direction() -> Vector2:
	return move_direction

func get_aim_direction() -> Vector2:
	return aim_direction

func get_last_valid_aim_direction() -> Vector2:
	return last_valid_aim_direction

func _get_move_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if direction.length() > 1.0:
		direction = direction.normalized()

	return direction

func _get_aim_direction(player_global_position: Vector2) -> Vector2:
	var controller_aim: Vector2 = Vector2.ZERO

	controller_aim.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	controller_aim.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")

	if controller_aim.length() >= DEADZONE:
		using_controller_aim = true
		using_mouse_aim = false
		return controller_aim.normalized()

	var viewport: Viewport = get_viewport()

	if viewport != null:
		var mouse_position: Vector2 = viewport.get_mouse_position()
		var canvas_transform: Transform2D = viewport.get_canvas_transform()
		var world_mouse_position: Vector2 = canvas_transform.affine_inverse() * mouse_position

		var mouse_direction: Vector2 = world_mouse_position - player_global_position

		if mouse_direction.length() > 0.01:
			using_mouse_aim = true
			using_controller_aim = false
			return mouse_direction.normalized()

	if move_direction.length() > 0.01:
		return move_direction.normalized()

	return last_valid_aim_direction

func _ensure_default_input_actions() -> void:
	_add_action_if_missing("move_left")
	_add_action_if_missing("move_right")
	_add_action_if_missing("move_up")
	_add_action_if_missing("move_down")

	_add_action_if_missing("aim_left")
	_add_action_if_missing("aim_right")
	_add_action_if_missing("aim_up")
	_add_action_if_missing("aim_down")

	_add_key_event("move_left", KEY_A)
	_add_key_event("move_left", KEY_LEFT)

	_add_key_event("move_right", KEY_D)
	_add_key_event("move_right", KEY_RIGHT)

	_add_key_event("move_up", KEY_W)
	_add_key_event("move_up", KEY_UP)

	_add_key_event("move_down", KEY_S)
	_add_key_event("move_down", KEY_DOWN)

func _add_action_if_missing(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

func _add_key_event(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode

	for existing_event: InputEvent in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
			return

	InputMap.action_add_event(action_name, event)
