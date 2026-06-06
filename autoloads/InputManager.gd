## Gerenciador central de input do protótipo.
##
## Responsabilidades:
## - ler direção de movimento;
## - ler direção de mira por analógico direito;
## - ler direção de mira por mouse;
## - manter a última direção válida de mira;
## - informar se o dash foi pressionado no frame atual.
##
## Observação importante:
## Este script apenas lê e normaliza input.
## Ele não move a Gaia, não executa dash e não dispara ataques diretamente.
extends Node

## Deadzone mínima utilizada para considerar input válido do analógico de mira.
const DEADZONE: float = 0.25

## Direção atual de movimento, calculada por WASD/setas ou actions equivalentes.
var move_direction: Vector2 = Vector2.ZERO

## Direção atual de mira.
##
## Pode vir do analógico direito, do mouse, do movimento como fallback,
## ou da última direção válida.
var aim_direction: Vector2 = Vector2.RIGHT

## Última direção de mira considerada válida.
##
## Garante que a Gaia nunca fique sem direção de ataque quando o jogador
## solta o mouse/analógico ou quando o input atual é neutro.
var last_valid_aim_direction: Vector2 = Vector2.RIGHT

## Informa se o botão de dash foi pressionado neste frame.
##
## Deve ser lido pelo PlayerController e consumido dentro do fluxo de dash.
var dash_just_pressed: bool = false

## Inicializa o gerenciador de input.
##
## As actions (move_*, aim_*, dash) são definidas no Input Map do projeto
## (Project Settings > Input Map), não mais criadas por código.
func _ready() -> void:
	DeveloperAuditLogger.log_lifecycle(
		"Input inicializado.",
		"InputManager"
	)

## Atualiza os inputs usados pelo player no frame atual.
##
## Recebe a posição global do player porque a mira por mouse depende
## da direção entre a Gaia e a posição mundial do cursor.
func update_input_for_player(player_global_position: Vector2) -> void:
	move_direction = _get_move_direction()
	aim_direction = _get_aim_direction(player_global_position)
	dash_just_pressed = Input.is_action_just_pressed("dash")

	## Se a mira atual for válida, ela passa a ser a última direção conhecida.
	## Caso contrário, reutiliza a última direção válida para evitar ataque
	## com vetor zero.
	if aim_direction.length() > 0.01:
		last_valid_aim_direction = aim_direction.normalized()
	else:
		aim_direction = last_valid_aim_direction

## Retorna a direção de movimento calculada no último update.
func get_move_direction() -> Vector2:
	return move_direction

## Retorna a direção de mira calculada no último update.
func get_aim_direction() -> Vector2:
	return aim_direction

## Retorna a última direção válida de mira.
func get_last_valid_aim_direction() -> Vector2:
	return last_valid_aim_direction

## Retorna true somente no frame em que o dash foi pressionado.
func was_dash_just_pressed() -> bool:
	return dash_just_pressed

## Calcula direção de movimento a partir das actions configuradas.
##
## Usa diferença entre direita/esquerda e baixo/cima.
## Normaliza diagonais para impedir velocidade maior em movimento diagonal.
func _get_move_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if direction.length() > 1.0:
		direction = direction.normalized()

	return direction

## Calcula a direção de mira atual.
##
## Prioridade:
## 1. analógico direito / actions de aim;
## 2. posição do mouse no mundo;
## 3. direção de movimento como fallback;
## 4. última direção válida.
func _get_aim_direction(player_global_position: Vector2) -> Vector2:
	var controller_aim: Vector2 = Vector2.ZERO

	controller_aim.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	controller_aim.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")

	## O analógico direito tem prioridade quando passa da deadzone.
	if controller_aim.length() >= DEADZONE:
		return controller_aim.normalized()

	var viewport: Viewport = get_viewport()

	if viewport != null:
		var mouse_position: Vector2 = viewport.get_mouse_position()
		var canvas_transform: Transform2D = viewport.get_canvas_transform()

		## Converte a posição do mouse da viewport para coordenadas de mundo,
		## respeitando câmera e transformações do canvas.
		var world_mouse_position: Vector2 = canvas_transform.affine_inverse() * mouse_position

		var mouse_direction: Vector2 = world_mouse_position - player_global_position

		if mouse_direction.length() > 0.01:
			return mouse_direction.normalized()

	## Fallback útil para teclado puro ou situações sem mira explícita.
	if move_direction.length() > 0.01:
		return move_direction.normalized()

	return last_valid_aim_direction
