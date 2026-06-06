## Estado runtime da Queen/player durante a run.
##
## Responsabilidades:
## - armazenar HP, defesa e velocidade atuais;
## - armazenar direções de movimento, mira e facing;
## - controlar estado de vida;
## - controlar estado de dash;
## - acumular dados de dano recebido;
## - armazenar multiplicadores de magnetismo/coleta;
## - controlar invencibilidade temporária.
##
## Importante:
## Este resource representa estado temporário da run.
## Ele não é save permanente.
extends Resource
class_name PlayerRuntimeState

## ID da Queen atual.
@export var queen_id: String = "gaia"

## HP máximo atual.
@export var max_hp: int = 100

## HP atual.
@export var current_hp: int = 100

## Defesa percentual atual.
@export var defense_percent: float = 0.0

## Velocidade de movimento atual.
@export var move_speed: float = 180.0

## Direção atual de movimento.
var move_direction: Vector2 = Vector2.ZERO

## Direção atual de mira.
var aim_direction: Vector2 = Vector2.RIGHT

## Última direção válida de mira.
var last_valid_aim_direction: Vector2 = Vector2.RIGHT

## Direção visual/facing da personagem.
##
## Atualmente usada principalmente para flip horizontal.
var facing_direction: Vector2 = Vector2.RIGHT

## Informa se a personagem está se movendo.
var is_moving: bool = false

## Informa se a personagem está em dash.
var is_dashing: bool = false

## Direção atual do dash.
var dash_direction: Vector2 = Vector2.ZERO

## Time scale visual usado pela animação de dash.
var dash_animation_time_scale: float = 1.0

## Informa se a personagem está viva.
var is_alive: bool = true

## Estado lógico atual de gameplay.
var current_gameplay_state: String = GameplayStateTypes.IDLE

## Estado visual atual.
var current_visual_state: String = GameplayStateTypes.IDLE

## Dano total recebido nesta run.
var total_damage_taken: int = 0

## Último dano recebido.
var last_damage_taken: int = 0

## ID da última fonte que causou dano.
var last_damage_source_id: String = ""

## Causa da morte, quando aplicável.
var death_cause: String = ""

## Multiplicador aplicado ao raio de magnetismo das moedas.
var coin_magnet_radius_multiplier: float = 1.0

## Multiplicador aplicado ao raio de coleta das moedas.
var coin_collect_radius_multiplier: float = 1.0

## Indica se o player está invencível.
var is_invincible: bool = false

## Tempo restante de invencibilidade.
var invincibility_timer: float = 0.0

## Inicializa o estado runtime a partir da QueenDefinition.
func setup_from_queen_definition(definition: QueenDefinition) -> void:
	queen_id = definition.id
	max_hp = definition.base_max_hp
	current_hp = max_hp
	move_speed = definition.base_move_speed

## Atualiza o estado lógico de gameplay.
func set_gameplay_state(new_state: String) -> void:
	if current_gameplay_state == new_state:
		return

	current_gameplay_state = new_state

## Aplica input normal de movimento e mira.
##
## Se estiver morto, bloqueia movimento e força estado DEAD.
## Se estiver em dash, mantém o estado DASHING e usa a direção do dash.
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

## Inicia estado de dash no runtime.
##
## Recebe direção, mira e escala de tempo visual da animação.
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

## Atualiza o estado de dash enquanto ele está ativo.
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

## Finaliza o dash e volta a aplicar input normal.
func finish_dash(move: Vector2, aim: Vector2) -> void:
	is_dashing = false
	dash_direction = Vector2.ZERO
	dash_animation_time_scale = 1.0

	apply_input(move, aim)

## Aplica dano final ao player.
##
## O cálculo de defesa já deve ter sido feito antes,
## normalmente pelo DamageResolver/PlayerController.
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

## Mata o player e limpa estados de movimento/dash.
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

## Cura o player sem ultrapassar o HP máximo.
func heal(amount: int) -> void:
	if amount <= 0:
		return

	if not is_alive:
		return

	current_hp = min(max_hp, current_hp + amount)

## Atualiza direção de mira e preserva última mira válida.
func _update_aim_direction(aim: Vector2) -> void:
	if aim.length() > 0.001:
		aim_direction = aim.normalized()
		last_valid_aim_direction = aim_direction
	else:
		aim_direction = last_valid_aim_direction

## Atualiza o facing visual a partir do movimento horizontal.
##
## A mira não controla o facing visual da Gaia.
func _update_visual_facing_from_movement(move: Vector2) -> void:
	if abs(move.x) <= 0.001:
		return

	if move.x < 0.0:
		facing_direction = Vector2.LEFT
	else:
		facing_direction = Vector2.RIGHT

## Define estado IDLE/MOVING/DEAD com base no movimento e vida.
func _update_movement_state() -> void:
	is_moving = move_direction.length() > 0.001

	if not is_alive:
		set_gameplay_state(GameplayStateTypes.DEAD)
	elif is_moving:
		set_gameplay_state(GameplayStateTypes.MOVING)
	else:
		set_gameplay_state(GameplayStateTypes.IDLE)
