## Moeda física coletável da run.
##
## Responsabilidades:
## - representar uma moeda dropada no mundo;
## - aguardar um pequeno tempo inicial;
## - detectar player para magnetismo;
## - acelerar em direção à Gaia;
## - emitir coleta quando entra no raio final;
## - impedir coleta após encerramento da run.
##
## Regra oficial:
## XP entra direto, mas moeda é drop físico e só conta se for coletada.
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

## Referências e estado físico runtime da moeda.
var player_node: Node2D = null

var velocity: Vector2 = Vector2.ZERO

var elapsed_seconds: float = 0.0

var is_collected: bool = false

var is_magnetized: bool = false

var collection_enabled: bool = true

var player_inside_magnet_area: bool = false

var player_inside_collect_area: bool = false

var last_applied_magnet_radius: float = -1.0

var last_applied_collect_radius: float = -1.0

## Aplica definition, localiza player e conecta evento de fim da run.
func _ready() -> void:
	_apply_definition()
	player_node = _resolve_player()
	_connect_area_signals()
	_refresh_area_radii()
	_refresh_area_overlap_state()
	_queue_debug_redraw()

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Atualiza magnetismo/coleta enquanto a moeda está ativa.
func _physics_process(delta: float) -> void:
	if is_collected:
		return

	elapsed_seconds += delta

	if not collection_enabled:
		return

	if player_node == null:
		player_node = _resolve_player()

	if player_node == null:
		return

	_refresh_area_radii()
	_refresh_area_overlap_state()

	if player_inside_collect_area:
		_collect()
		return

	if elapsed_seconds < initial_idle_seconds:
		is_magnetized = false
		return

	if player_inside_magnet_area:
		is_magnetized = true
		_update_magnet_movement(delta)
	else:
		is_magnetized = false
		velocity = velocity.move_toward(Vector2.ZERO, magnet_acceleration * delta)

	global_position += velocity * delta
	_queue_debug_redraw()

## Reagenda o _draw apenas quando o visual de debug está ligado.
##
# Evita marcar o canvas como "dirty" a cada frame em muitas moedas com debug desligado.
func _queue_debug_redraw() -> void:
	if draw_debug_visual:
		queue_redraw()

## Desenha visual técnico/placeholder da moeda quando habilitado.
func _draw() -> void:
	if not draw_debug_visual:
		return

	draw_circle(Vector2.ZERO, debug_radius, debug_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, debug_outline_color, 2.0)

	if is_magnetized:
		draw_arc(Vector2.ZERO, _get_effective_magnet_radius(), 0.0, TAU, 48, Color(1.0, 0.9, 0.2, 0.18), 1.0)

## Configura a moeda em runtime com definition, valor e player opcional.
func setup(p_definition: CoinDropDefinition, p_value: int = 1, p_player: Node2D = null) -> void:
	coin_definition = p_definition
	value = max(1, p_value)

	if p_player != null:
		player_node = p_player

	_apply_definition()
	_refresh_area_radii()
	_refresh_area_overlap_state()
	_queue_debug_redraw()

## Copia dados da CoinDropDefinition para campos runtime.
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

## Conecta os sinais nativos das áreas de magnetismo e coleta.
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

## Atualiza os raios efetivos das áreas a partir da definition e dos modificadores do player.
func _refresh_area_radii() -> void:
	var effective_magnet_radius: float = _get_effective_magnet_radius()
	var effective_collect_radius: float = _get_effective_collect_radius()

	if not is_equal_approx(last_applied_magnet_radius, effective_magnet_radius):
		_set_area_radius(magnet_collision_shape, effective_magnet_radius)
		last_applied_magnet_radius = effective_magnet_radius

	if not is_equal_approx(last_applied_collect_radius, effective_collect_radius):
		_set_area_radius(collect_collision_shape, effective_collect_radius)
		last_applied_collect_radius = effective_collect_radius

## Aplica um raio em um CircleShape2D de forma segura.
func _set_area_radius(shape_node: CollisionShape2D, radius: float) -> void:
	if shape_node == null:
		return

	var circle_shape: CircleShape2D = shape_node.shape as CircleShape2D

	if circle_shape == null:
		return

	circle_shape.radius = max(1.0, radius)

## Sincroniza flags de overlap usando a consulta nativa da Area2D.
##
## Isso cobre casos de pool/reuso e mudanças de raio em runtime sem voltar ao cálculo manual
## de distância para iniciar magnetismo ou coleta.
func _refresh_area_overlap_state() -> void:
	player_inside_magnet_area = _area_has_player_body(magnet_area)
	player_inside_collect_area = _area_has_player_body(collect_area)

## Verifica se a Area2D contém algum body do player esperado.
func _area_has_player_body(area: Area2D) -> bool:
	if area == null:
		return false

	for body: Node in area.get_overlapping_bodies():
		if _is_valid_player_body(body):
			return true

	return false

## Calcula atração da moeda até o player e move sua posição.
func _update_magnet_movement(delta: float) -> void:
	var to_player: Vector2 = player_node.global_position - global_position

	if to_player.length() <= 0.001:
		return

	var desired_velocity: Vector2 = to_player.normalized() * max_magnet_speed
	velocity = velocity.move_toward(desired_velocity, magnet_acceleration * delta)

## Marca como coletada, emite evento e remove a moeda.
func _collect() -> void:
	if not collection_enabled:
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

	# Devolve a moeda ao pool (fallback para queue_free se não for poolada).
	PoolManager.despawn(self)

## Hook do pool: reseta o estado runtime antes de reusar a moeda.
##
## O setup() reaplica a definition e o valor logo em seguida.
func _on_pool_acquire() -> void:
	is_collected = false
	is_magnetized = false
	collection_enabled = true
	player_inside_magnet_area = false
	player_inside_collect_area = false
	velocity = Vector2.ZERO
	elapsed_seconds = 0.0
	last_applied_magnet_radius = -1.0
	last_applied_collect_radius = -1.0

## Localiza o primeiro Node2D no grupo de player.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

## Bloqueia coleta quando a run termina.
func _on_run_finished(_result_payload: RunResultPayload) -> void:
	collection_enabled = false
	is_magnetized = false
	player_inside_magnet_area = false
	player_inside_collect_area = false
	velocity = Vector2.ZERO
	_queue_debug_redraw()

## Calcula raio de magnetismo com multiplicador do player, quando existir.
func _get_effective_magnet_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_magnet_radius_multiplier")
	return magnet_radius * multiplier

## Calcula raio de coleta com multiplicador do player, quando existir.
func _get_effective_collect_radius() -> float:
	var multiplier: float = _get_player_collection_multiplier("coin_collect_radius_multiplier")
	return collect_radius * multiplier

## Consulta multiplicador de coleta/magnetismo no player, se disponível.
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

## body_entered do MagnetArea: ativa estado quando o player entra no raio.
func _on_magnet_area_body_entered(body: Node) -> void:
	if _is_valid_player_body(body):
		player_inside_magnet_area = true

## body_exited do MagnetArea: desativa estado quando o player sai do raio.
func _on_magnet_area_body_exited(body: Node) -> void:
	if _is_valid_player_body(body):
		player_inside_magnet_area = _area_has_player_body(magnet_area)

## body_entered do CollectArea: registra overlap e coleta imediatamente se permitido.
func _on_collect_area_body_entered(body: Node) -> void:
	if not _is_valid_player_body(body):
		return

	player_inside_collect_area = true

	if collection_enabled and not is_collected:
		_collect()

## body_exited do CollectArea: atualiza estado quando o player sai do raio final.
func _on_collect_area_body_exited(body: Node) -> void:
	if _is_valid_player_body(body):
		player_inside_collect_area = _area_has_player_body(collect_area)

## Valida se um body pertence ao player detectável pela moeda.
func _is_valid_player_body(body: Node) -> bool:
	if body == null:
		return false

	if player_node != null and body == player_node:
		return true

	return body.is_in_group(player_group_name)
