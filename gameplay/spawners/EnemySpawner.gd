## Spawner de inimigos da arena.
##
## Responsabilidades:
## - resolver player e EnemyRoot;
## - usar SpawnTimelineDefinition do mapa quando configurado;
## - aplicar SpawnTimelineEntryDefinition ativa;
## - instanciar inimigos fora da tela/ao redor do player;
## - configurar EnemyDefinition no EnemyBase;
## - respeitar limites de quantidade e delay inicial.
##
## O spawner cria inimigos, mas não controla comportamento de combate diretamente.
extends Node


## Configurações básicas de ativação do sistema.
@export_group("Base")

@export var spawner_enabled: bool = true

@export var spawn_on_ready: bool = true

@export var player_group_name: String = "player"


## Configuração do inimigo instanciado.
@export_group("Enemy")

@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

@export var enemy_definition: EnemyDefinition


## Referências aos roots da cena onde objetos serão adicionados.
@export_group("Scene Roots")

@export var enemy_root_path: NodePath


## Valores usados quando não há timeline ativa ou como fallback de spawn.
@export_group("Spawn Fallback")

@export var spawn_interval_seconds: float = 2.2

@export var max_alive_enemies: int = 18

@export var spawn_min_distance: float = 420.0

@export var spawn_max_distance: float = 620.0


## Proteções para evitar spawn injusto ou duplicado.
@export_group("Spawn Safety")

@export var initial_spawn_delay_seconds: float = 0.45

@export var spawn_position_attempts: int = 16

@export var minimum_safe_spawn_distance_from_player: float = 360.0

@export var prevent_multiple_spawns_same_frame: bool = true

@export var log_spawn_distance: bool = true


## Configurações para spawn controlado por timeline do mapa.
@export_group("Timeline")

@export var use_map_spawn_timeline: bool = true

@export var spawn_timeline_definition: SpawnTimelineDefinition

@export var log_timeline_changes: bool = true


## Pré-aquecimento do pool de inimigos.
@export_group("Pooling")

## Quantidade de inimigos pré-criados no pool no _ready, evitando hitch no início.
## 0 desliga o pré-aquecimento.
@export var prewarm_pool_count: int = 24

var player_node: Node2D = null

var enemy_root: Node2D = null

var spawn_timer: float = 0.0

var active_entry_id: String = ""

var elapsed_since_ready: float = 0.0

var last_spawn_frame: int = -1

var initial_spawn_delay_completed: bool = false

# Contador incremental de inimigos vivos (++ ao spawnar, -- no enemy_died).
# Evita varrer o grupo "enemy" a cada spawn; leitura em O(1).
var _alive_enemy_count: int = 0


## Resolve referências iniciais, timeline e delay de spawn.
func _ready() -> void:
	enemy_root = _resolve_enemy_root()
	player_node = _resolve_player()
	_resolve_spawn_timeline_from_map()

	# Pré-aquece o pool de inimigos para evitar hitch nas primeiras waves.
	if prewarm_pool_count > 0 and enemy_scene_path.strip_edges() != "":
		PoolManager.prewarm_path(enemy_scene_path, prewarm_pool_count)

	if spawn_on_ready:
		spawn_timer = max(0.0, initial_spawn_delay_seconds)
	else:
		spawn_timer = spawn_interval_seconds

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

	if not GameEvents.enemy_died.is_connected(_on_enemy_died_count):
		GameEvents.enemy_died.connect(_on_enemy_died_count)


## Atualiza timer de spawn e instancia inimigos quando permitido.
func _process(delta: float) -> void:
	if not spawner_enabled:
		return

	elapsed_since_ready += delta

	if player_node == null:
		player_node = _resolve_player()

	if enemy_root == null:
		enemy_root = _resolve_enemy_root()

	if player_node == null or enemy_root == null:
		return

	_update_timeline_values()

	if elapsed_since_ready < initial_spawn_delay_seconds:
		return

	if not initial_spawn_delay_completed:
		initial_spawn_delay_completed = true
		spawn_timer = min(spawn_timer, 0.05)

		DeveloperAuditLogger.log_spawn(
			"Delay inicial concluído. Spawner liberado.",
			"EnemySpawner"
		)

	spawn_timer -= delta

	if spawn_timer <= 0.0:
		var spawned: bool = force_spawn_enemy()

		if spawned:
			spawn_timer = spawn_interval_seconds
		else:
			spawn_timer = min(0.5, spawn_interval_seconds)


## Recebe explicitamente o player instanciado pela cena.
func configure_player(player: Node2D) -> void:
	player_node = player

	if player_node != null:
		DeveloperAuditLogger.log_spawn(
			"Player configurado pela cena: %s" % player.name,
			"EnemySpawner",
			{
				"player_name": player.name
			}
		)


## Recebe explicitamente o root onde inimigos serão adicionados.
func configure_enemy_root(root: Node2D) -> void:
	enemy_root = root

	if enemy_root != null:
		DeveloperAuditLogger.log_spawn(
			"EnemyRoot configurado pela cena: %s" % root.name,
			"EnemySpawner",
			{
				"enemy_root": root.name
			}
		)


## Cria um inimigo imediatamente para testes ou fluxo normal de spawn.
func force_spawn_enemy() -> bool:
	if not spawner_enabled:
		return false

	if prevent_multiple_spawns_same_frame:
		var current_frame: int = Engine.get_process_frames()

		if current_frame == last_spawn_frame:
			return false

	if player_node == null:
		player_node = _resolve_player()

	if enemy_root == null:
		enemy_root = _resolve_enemy_root()

	if player_node == null:
		push_warning("[EnemySpawner] Spawn cancelado: player ausente.")
		return false

	if enemy_root == null:
		push_warning("[EnemySpawner] Spawn cancelado: EnemyRoot ausente.")
		return false

	var alive_count: int = _get_alive_enemy_count()

	if alive_count >= max_alive_enemies:
		return false

	if enemy_scene_path.strip_edges() == "":
		push_warning("[EnemySpawner] enemy_scene_path vazio.")
		return false

	# Calcula a posição antes do spawn para o inimigo já nascer no lugar certo
	# (o pool aplica a posição antes do add_child, evitando 1 frame na origem).
	var spawn_position: Vector2 = _get_safe_spawn_position_around_player()

	# Adquire o inimigo do pool (reutiliza instância morta quando houver).
	var enemy_instance: Node = PoolManager.spawn_path(enemy_scene_path, enemy_root, spawn_position)

	if not enemy_instance is Node2D:
		push_warning("[EnemySpawner] Enemy scene inválida ou não é Node2D: %s" % enemy_scene_path)

		if enemy_instance != null:
			PoolManager.despawn(enemy_instance)

		return false

	var enemy_node: Node2D = enemy_instance as Node2D
	var distance_to_player: float = spawn_position.distance_to(player_node.global_position)

	if enemy_node.has_method("setup"):
		enemy_node.call("setup", enemy_definition, player_node)

	last_spawn_frame = Engine.get_process_frames()
	_alive_enemy_count += 1

	distance_to_player = enemy_node.global_position.distance_to(player_node.global_position)

	if log_spawn_distance:
		DeveloperAuditLogger.log_spawn(
			"Inimigo criado em: %s | dist_player=%s | vivos=%s | wave=%s" % [
				str(enemy_node.global_position),
				str(distance_to_player),
				str(_get_alive_enemy_count()),
				active_entry_id
			],
			"EnemySpawner",
			{
				"position": enemy_node.global_position,
				"distance_to_player": distance_to_player,
				"alive_count": _get_alive_enemy_count(),
				"wave_id": active_entry_id
			}
		)

	return true


## Atualiza configurações atuais com base na entry ativa da timeline.
func _update_timeline_values() -> void:
	if spawn_timeline_definition == null:
		_resolve_spawn_timeline_from_map()

	if spawn_timeline_definition == null:
		return

	var run_state: RunState = RunQuery.get_run_state(get_tree())
	var elapsed_seconds: float = 0.0

	if run_state != null:
		elapsed_seconds = run_state.elapsed_seconds

	var active_entry: SpawnTimelineEntryDefinition = spawn_timeline_definition.get_active_entry(elapsed_seconds)

	if active_entry == null:
		return

	if active_entry.id != active_entry_id:
		_apply_timeline_entry(active_entry, true)
	else:
		_apply_timeline_entry(active_entry, false)


## Aplica dados da SpawnTimelineEntryDefinition ativa.
func _apply_timeline_entry(entry: SpawnTimelineEntryDefinition, changed: bool) -> void:
	if entry == null:
		return

	active_entry_id = entry.id

	if entry.enemy_scene_path.strip_edges() != "":
		enemy_scene_path = entry.enemy_scene_path

	if entry.enemy_definition != null:
		enemy_definition = entry.enemy_definition

	spawn_interval_seconds = entry.spawn_interval_seconds
	max_alive_enemies = entry.max_alive_enemies
	spawn_min_distance = entry.spawn_min_distance
	spawn_max_distance = entry.spawn_max_distance

	if not changed:
		return

	spawn_timer = min(spawn_timer, spawn_interval_seconds)

	if log_timeline_changes:
		DeveloperAuditLogger.log_spawn(
			"Wave ativa: %s | interval=%s max_alive=%s dist=%s-%s" % [
				entry.id,
				str(spawn_interval_seconds),
				str(max_alive_enemies),
				str(spawn_min_distance),
				str(spawn_max_distance)
			],
			"EnemySpawner",
			{
				"wave_id": entry.id,
				"spawn_interval_seconds": spawn_interval_seconds,
				"max_alive_enemies": max_alive_enemies,
				"spawn_min_distance": spawn_min_distance,
				"spawn_max_distance": spawn_max_distance
			}
		)

	if not entry.spawn_on_activate:
		return

	if not initial_spawn_delay_completed:
		spawn_timer = min(spawn_timer, max(0.05, initial_spawn_delay_seconds - elapsed_since_ready))
		return

	var spawned: bool = force_spawn_enemy()

	if spawned:
		spawn_timer = spawn_interval_seconds

## Obtém timeline a partir do MapDefinition/RunController quando configurado.
func _resolve_spawn_timeline_from_map() -> void:
	if spawn_timeline_definition != null:
		return

	if not use_map_spawn_timeline:
		return

	var run_controller: Node = RunQuery.get_run_controller(get_tree())

	if run_controller == null:
		return

	if not run_controller.has_method("get_map_definition"):
		return

	var map_definition_variant: Variant = run_controller.call("get_map_definition")

	if map_definition_variant is MapDefinition:
		var map_definition: MapDefinition = map_definition_variant as MapDefinition

		if map_definition.spawn_timeline != null:
			spawn_timeline_definition = map_definition.spawn_timeline

			DeveloperAuditLogger.log_spawn(
				"SpawnTimeline resolvida: %s" % spawn_timeline_definition.id,
				"EnemySpawner",
				{
					"timeline_id": spawn_timeline_definition.id
				}
			)

## Tenta gerar posição segura ao redor do player respeitando distância mínima.
func _get_safe_spawn_position_around_player() -> Vector2:
	var safe_min_distance: float = max(minimum_safe_spawn_distance_from_player, spawn_min_distance)
	var safe_max_distance: float = max(safe_min_distance + 1.0, spawn_max_distance)

	var best_position: Vector2 = player_node.global_position + Vector2.RIGHT * safe_min_distance
	var best_distance: float = 0.0

	for attempt: int in range(max(1, spawn_position_attempts)):
		var candidate_position: Vector2 = _get_spawn_position_around_player(safe_min_distance, safe_max_distance)
		var distance_to_player: float = candidate_position.distance_to(player_node.global_position)

		if distance_to_player >= safe_min_distance:
			return candidate_position

		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_position = candidate_position

	return best_position

## Gera posição aleatória em anel ao redor da Gaia.
func _get_spawn_position_around_player(min_distance: float, max_distance: float) -> Vector2:
	var safe_min_distance: float = max(0.0, min_distance)
	var safe_max_distance: float = max(safe_min_distance, max_distance)

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(safe_min_distance, safe_max_distance)

	return player_node.global_position + Vector2(cos(angle), sin(angle)) * distance

## Retorna a contagem de inimigos vivos em O(1) (contador incremental).
func _get_alive_enemy_count() -> int:
	return _alive_enemy_count

## Decrementa o contador quando um inimigo morre (signal global enemy_died).
func _on_enemy_died_count(
	_enemy_id: String,
	_source_id: String,
	_xp_reward: int,
	_enemy_global_position: Vector2,
	_coin_drop_chance: float,
	_coin_drop_value: int
) -> void:
	_alive_enemy_count = max(0, _alive_enemy_count - 1)

## Localiza root de inimigos por path ou fallback.
func _resolve_enemy_root() -> Node2D:
	if enemy_root_path != NodePath():
		var configured_root: Node = get_node_or_null(enemy_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var direct_sibling: Node = get_node_or_null("../EnemyRoot")

	if direct_sibling is Node2D:
		return direct_sibling as Node2D

	var parent_node: Node = get_parent()

	while parent_node != null:
		var found_root: Node = parent_node.get_node_or_null("EnemyRoot")

		if found_root is Node2D:
			return found_root as Node2D

		parent_node = parent_node.get_parent()

	return null

## Localiza player por referência explícita ou grupo.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

## Desativa spawn quando a run termina.
func _on_run_finished(_result_payload: RunResultPayload) -> void:
	spawner_enabled = false

	DeveloperAuditLogger.log_spawn(
		"Desativado após fim da run.",
		"EnemySpawner"
	)

## Configuração em lote usada pela cena para player/root.
func configure_spawner(player: Node2D, root: Node2D) -> void:
	configure_player(player)
	configure_enemy_root(root)
