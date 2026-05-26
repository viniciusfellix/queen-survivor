## Moeda física dropada durante a run.
##
## Regras atuais:
## - nasce no mundo após morte válida de inimigo;
## - aguarda pequeno tempo inicial;
## - é atraída ao entrar no raio de magnetismo;
## - é contabilizada somente ao entrar no raio de coleta;
## - deixa de ser coletável após o fim da run.
extends Node2D
class_name CoinDrop

## Definition com parâmetros base desta moeda.
@export var coin_definition: CoinDropDefinition

## Quantidade adicionada ao saldo quando esta moeda for coletada.
@export var value: int = 1

## Grupo utilizado para localizar automaticamente a Queen.
@export var player_group_name: String = "player"

## Distância base para iniciar atração magnética.
@export var magnet_radius: float = 150.0

## Distância base para concluir a coleta.
@export var collect_radius: float = 24.0

## Tempo inicial em que a moeda permanece parada antes do magnetismo.
@export var initial_idle_seconds: float = 0.15

## Aceleração utilizada durante movimento magnético.
@export var magnet_acceleration: float = 900.0

## Velocidade máxima atingida durante atração.
@export var max_magnet_speed: float = 520.0

## Exibe visual técnico temporário da moeda.
@export var draw_debug_visual: bool = true

## Raio do placeholder desenhado.
@export var debug_radius: float = 8.0

## Cor principal do placeholder.
@export var debug_color: Color = Color(1.0, 0.78, 0.18, 1.0)

## Cor de contorno do placeholder.
@export var debug_outline_color: Color = Color(1.0, 1.0, 1.0, 0.95)

## Referência atual da Queen que pode coletar a moeda.
var player_node: Node2D = null

## Velocidade runtime atual da moeda.
var velocity: Vector2 = Vector2.ZERO

## Tempo transcorrido desde o nascimento da moeda.
var elapsed_seconds: float = 0.0

## Define se a moeda já foi coletada e não pode emitir novamente.
var is_collected: bool = false

## Define se a moeda está atualmente sendo atraída.
var is_magnetized: bool = false

## Define se esta moeda ainda pode entrar no saldo da run.
var collection_enabled: bool = true

## Inicializa parâmetros, localiza o player e escuta o fim da run.
func _ready() -> void:
	_apply_definition()
	player_node = _resolve_player()
	queue_redraw()

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Atualiza magnetismo e coleta física da moeda.
##
## Durante pausas ou após encerramento do gameplay, interrompe movimento
## e impede que a moeda seja coletada indevidamente.
func _physics_process(delta: float) -> void:
	if is_collected:
		return

	elapsed_seconds += delta

	if not collection_enabled:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		is_magnetized = false
		velocity = Vector2.ZERO
		queue_redraw()
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

## Desenha placeholder técnico e raio magnético quando aplicável.
func _draw() -> void:
	if not draw_debug_visual:
		return

	draw_circle(Vector2.ZERO, debug_radius, debug_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, debug_outline_color, 2.0)

	if is_magnetized:
		draw_arc(Vector2.ZERO, _get_effective_magnet_radius(), 0.0, TAU, 48, Color(1.0, 0.9, 0.2, 0.18), 1.0)

## Configura a moeda criada pelo `DropController`.
##
## Permite fornecer definition, valor específico e referência direta
## da Queen que participará do magnetismo.
func setup(p_definition: CoinDropDefinition, p_value: int = 1, p_player: Node2D = null) -> void:
	coin_definition = p_definition
	value = max(1, p_value)

	if p_player != null:
		player_node = p_player

	_apply_definition()
	queue_redraw()

## Copia parâmetros editáveis da definition para esta instância runtime.
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

## Acelera a moeda em direção ao player enquanto estiver magnetizada.
func _update_magnet_movement(delta: float) -> void:
	var to_player: Vector2 = player_node.global_position - global_position

	if to_player.length() <= 0.001:
		return

	var desired_velocity: Vector2 = to_player.normalized() * max_magnet_speed
	velocity = velocity.move_toward(desired_velocity, magnet_acceleration * delta)

## Conclui a coleta física e informa o saldo à run.
##
## A moeda só é removida depois de emitir `run_coin_collected`.
func _collect() -> void:
	if not collection_enabled:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	if is_collected:
		return

	is_collected = true

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

	queue_free()

## Resolve automaticamente a Queen pelo grupo configurado.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

## Interrompe permanentemente coleta e magnetismo quando a run termina.
##
## Isso garante que moedas deixadas no chão sejam perdidas conforme
## a regra oficial do jogo.
func _on_run_finished(_result_payload: RunResultPayload) -> void:
	collection_enabled = false
	is_magnetized = false
	velocity = Vector2.ZERO
	queue_redraw()

## Calcula o raio magnético efetivo considerando upgrades do player.
func _get_effective_magnet_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_magnet_radius_multiplier")
	return magnet_radius * multiplier

## Calcula o raio de coleta efetivo considerando upgrades do player.
func _get_effective_collect_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_collect_radius_multiplier")
	return collect_radius * multiplier

## Obtém do player um multiplicador de coleta por chave.
##
## Em ausência de contrato compatível, utiliza multiplicador neutro.
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
