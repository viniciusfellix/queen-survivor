## Estado mutável da Queen controlada pelo jogador durante uma única run.
##
## Este resource não representa dados permanentes da personagem.
## Ele armazena somente informações runtime, como:
## - HP atual;
## - defesa e velocidade após upgrades;
## - direções de movimento e mira;
## - estado visual/gameplay;
## - dano recebido;
## - multiplicadores de coleta;
## - janela de invencibilidade após dano.
extends Resource
class_name PlayerRuntimeState

## ID técnico da Queen controlada nesta run.
@export var queen_id: String = "gaia"

## Vida máxima atual da Queen.
##
## Pode ser aumentada durante a run por upgrades.
@export var max_hp: int = 100

## Vida restante atual da Queen.
@export var current_hp: int = 100

## Percentual de redução aplicado ao dano recebido.
##
## No fluxo atual, o `PlayerController` limita o valor efetivo
## para evitar defesa absoluta permanente.
@export var defense_percent: float = 0.0

## Velocidade de deslocamento atual da Queen.
##
## Pode ser modificada por upgrades percentuais durante a run.
@export var move_speed: float = 180.0

## Direção de movimento informada pelo sistema de input.
var move_direction: Vector2 = Vector2.ZERO

## Direção utilizada para ataques direcionais.
##
## Mouse e analógico direito podem alterar esta direção
## independentemente do movimento corporal da personagem.
var aim_direction: Vector2 = Vector2.RIGHT

## Última direção de mira válida registrada.
##
## Garante que a arma continue apontando para alguma direção
## mesmo quando nenhum input atual de mira está presente.
var last_valid_aim_direction: Vector2 = Vector2.RIGHT

## Direção horizontal utilizada para inverter visualmente o corpo.
##
## No Módulo 1, a aparência da Gaia acompanha o movimento horizontal,
## e não a direção livre da mira.
var facing_direction: Vector2 = Vector2.RIGHT

## Informa se a Queen está se deslocando neste frame.
var is_moving: bool = false

## Informa se a Queen ainda pode atuar na run.
var is_alive: bool = true

## Estado lógico atual usado para orientar comportamento e animação.
var current_gameplay_state: String = GameplayStateTypes.IDLE

## Estado visual aplicado pelo controller de animação.
var current_visual_state: String = GameplayStateTypes.IDLE

## Soma de todo dano efetivamente recebido durante a run.
var total_damage_taken: int = 0

## Último valor de dano efetivamente recebido.
var last_damage_taken: int = 0

## ID da última fonte que causou dano à Queen.
var last_damage_source_id: String = ""

## ID da fonte responsável pela morte da Queen.
var death_cause: String = ""

## Multiplicador aplicado ao raio de magnetismo das moedas.
var coin_magnet_radius_multiplier: float = 1.0

## Multiplicador aplicado ao raio final de coleta das moedas.
var coin_collect_radius_multiplier: float = 1.0

## Define se a Queen está temporariamente imune a novos impactos.
var is_invincible: bool = false

## Tempo restante da janela de invencibilidade após dano.
var invincibility_timer: float = 0.0

## Inicializa os atributos base da run a partir da definição da Queen.
##
## Atualmente importa identificação, HP máximo e velocidade inicial.
## Upgrades e modificadores runtime são aplicados posteriormente.
func setup_from_queen_definition(definition: QueenDefinition) -> void:
	queen_id = definition.id
	max_hp = definition.base_max_hp
	current_hp = max_hp
	move_speed = definition.base_move_speed

## Atualiza o estado lógico da personagem apenas quando houver mudança real.
##
## Esta proteção reduz processamento e evita solicitações visuais repetidas.
func set_gameplay_state(new_state: String) -> void:
	if current_gameplay_state == new_state:
		return

	current_gameplay_state = new_state

## Aplica movimento e mira recebidos do `InputManager`.
##
## Quando a Queen está morta, bloqueia movimentação, mas mantém
## atualização de mira segura antes de fixar o estado `DEAD`.
func apply_input(move: Vector2, aim: Vector2) -> void:
	if not is_alive:
		move_direction = Vector2.ZERO
		_update_aim_direction(aim)
		set_gameplay_state(GameplayStateTypes.DEAD)
		return

	move_direction = move

	_update_aim_direction(aim)
	_update_visual_facing_from_movement(move_direction)
	_update_movement_state()

## Aplica dano final já resolvido contra a Queen.
##
## Este método não calcula defesa ou tipos de dano:
## recebe o valor final do `DamageResolver`, atualiza estatísticas
## e mata a personagem quando o HP chega a zero.
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

## Consolida a morte da Queen na run atual.
##
## Interrompe movimento e registra a causa da derrota.
## A finalização da run é coordenada posteriormente pelo `RunController`
## ao receber o signal emitido pelo `PlayerController`.
func kill(source_id: String = "") -> void:
	if not is_alive:
		return

	is_alive = false
	current_hp = 0
	death_cause = source_id

	move_direction = Vector2.ZERO
	is_moving = false

	set_gameplay_state(GameplayStateTypes.DEAD)

## Recupera HP sem ultrapassar o máximo atual.
##
## Não permite cura em personagens mortas.
func heal(amount: int) -> void:
	if amount <= 0:
		return

	if not is_alive:
		return

	current_hp = min(max_hp, current_hp + amount)

## Atualiza a direção de mira, preservando a última direção válida.
##
## Evita ataques sem orientação quando o jogador para de mover
## mouse ou analógico.
func _update_aim_direction(aim: Vector2) -> void:
	if aim.length() > 0.001:
		aim_direction = aim.normalized()
		last_valid_aim_direction = aim_direction
	else:
		aim_direction = last_valid_aim_direction

## Atualiza somente a orientação horizontal do corpo da Queen.
##
## A mira não vira o corpo no protótipo atual. Isso permite mirar
## em uma direção enquanto a personagem continua visualmente correndo
## para outro lado.
func _update_visual_facing_from_movement(move: Vector2) -> void:
	if abs(move.x) <= 0.001:
		return

	if move.x < 0.0:
		facing_direction = Vector2.LEFT
	else:
		facing_direction = Vector2.RIGHT

## Deriva o estado lógico básico de movimento da Queen.
##
## Prioridade atual:
## - morta;
## - movendo;
## - parada.
func _update_movement_state() -> void:
	is_moving = move_direction.length() > 0.001

	if not is_alive:
		set_gameplay_state(GameplayStateTypes.DEAD)
	elif is_moving:
		set_gameplay_state(GameplayStateTypes.MOVING)
	else:
		set_gameplay_state(GameplayStateTypes.IDLE)
