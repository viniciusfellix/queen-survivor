## Gerenciador global de entrada do player.
##
## Centraliza:
## - direção de movimento por teclado;
## - direção de mira por analógico direito ou mouse;
## - preservação da última direção válida de mira.
##
## A Gaia consulta este autoload a cada atualização para mover o corpo e
## orientar sua arma direcional de forma independente.
extends Node

## Zona morta mínima aplicada ao analógico de mira.
## Valores menores são ignorados para evitar direção instável por ruído.
const DEADZONE: float = 0.25

## Direção atual de movimento, normalizada quando necessário.
var move_direction: Vector2 = Vector2.ZERO

## Direção atual de mira utilizada pela arma.
var aim_direction: Vector2 = Vector2.RIGHT

## Última direção de mira válida, reutilizada quando não existe input novo.
var last_valid_aim_direction: Vector2 = Vector2.RIGHT

## Garante que as ações mínimas de input existam e registra inicialização.
func _ready() -> void:
	_ensure_default_input_actions()

	DeveloperAuditLogger.log_lifecycle(
		"Input inicializado.",
		"InputManager"
	)

## Atualiza movimento e mira com base na posição atual do player.
##
## A posição global é necessária para converter o mouse em direção no mundo.
## Quando nenhuma mira válida é encontrada, mantém a última direção utilizada.
func update_input_for_player(player_global_position: Vector2) -> void:
	move_direction = _get_move_direction()
	aim_direction = _get_aim_direction(player_global_position)

	if aim_direction.length() > 0.01:
		last_valid_aim_direction = aim_direction.normalized()
	else:
		aim_direction = last_valid_aim_direction

## Retorna a direção atual de movimento.
func get_move_direction() -> Vector2:
	return move_direction

## Retorna a direção atual de mira.
func get_aim_direction() -> Vector2:
	return aim_direction

## Retorna a última direção de mira que possuía magnitude válida.
func get_last_valid_aim_direction() -> Vector2:
	return last_valid_aim_direction

## Calcula a direção de movimento usando as ações configuradas.
##
## Movimento diagonal é normalizado para não aumentar a velocidade final.
func _get_move_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if direction.length() > 1.0:
		direction = direction.normalized()

	return direction

## Calcula a direção de mira seguindo a prioridade atual:
## 1. analógico direito, quando ultrapassa a zona morta;
## 2. posição do mouse convertida para coordenadas de mundo;
## 3. direção de movimento, caso exista;
## 4. última direção válida registrada.
func _get_aim_direction(player_global_position: Vector2) -> Vector2:
	var controller_aim: Vector2 = Vector2.ZERO

	controller_aim.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	controller_aim.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")

	if controller_aim.length() >= DEADZONE:
		return controller_aim.normalized()

	var viewport: Viewport = get_viewport()

	if viewport != null:
		var mouse_position: Vector2 = viewport.get_mouse_position()
		var canvas_transform: Transform2D = viewport.get_canvas_transform()
		var world_mouse_position: Vector2 = canvas_transform.affine_inverse() * mouse_position

		var mouse_direction: Vector2 = world_mouse_position - player_global_position

		if mouse_direction.length() > 0.01:
			return mouse_direction.normalized()

	if move_direction.length() > 0.01:
		return move_direction.normalized()

	return last_valid_aim_direction

## Garante as ações mínimas utilizadas pelo protótipo.
##
## As ações de movimento recebem bindings de teclado padrão.
## As ações de mira são criadas para suportar configuração de controle
## pelo Input Map, mas não recebem bindings de teclado automaticamente.
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

## Cria uma ação no Input Map apenas quando ela ainda não existir.
func _add_action_if_missing(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

## Vincula uma tecla física a uma ação sem criar bindings duplicados.
func _add_key_event(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode

	for existing_event: InputEvent in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
			return

	InputMap.action_add_event(action_name, event)
