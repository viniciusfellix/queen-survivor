extends Node

@export_group("Base")

@export var spawner_enabled: bool = true

@export var spawn_on_ready: bool = true

@export var player_group_name: String = "player"

@export_group("Enemy")

@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"

@export var enemy_definition: EnemyDefinition

@export_group("Scene Roots")

@export var enemy_root_path: NodePath

@export_group("Spawn Fallback")

@export var spawn_interval_seconds: float = 2.2

@export var max_alive_enemies: int = 18

@export var spawn_min_distance: float = 420.0

@export var spawn_max_distance: float = 620.0

@export_group("Spawn Safety")

@export var initial_spawn_delay_seconds: float = 0.45

@export var spawn_position_attempts: int = 16

@export var minimum_safe_spawn_distance_from_player: float = 360.0

@export var prevent_multiple_spawns_same_frame: bool = true

@export var log_spawn_distance: bool = true

@export_group("Timeline")

@export var use_map_spawn_timeline: bool = true

@export var spawn_timeline_definition: SpawnTimelineDefinition

@export var log_timeline_changes: bool = true

var player_node: Node2D = null

var enemy_root: Node2D = null

var spawn_timer: float = 0.0

var active_entry_id: String = ""

var elapsed_since_ready: float = 0.0

var last_spawn_frame: int = -1

var initial_spawn_delay_completed: bool = false

func _ready() -> void:
	enemy_root = _resolve_enemy_root()
	player_node = _resolve_player()
	_resolve_spawn_timeline_from_map()

	if spawn_on_ready:
		spawn_timer = max(0.0, initial_spawn_delay_seconds)
	else:
		spawn_timer = spawn_interval_seconds

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

func _process(delta: float) -> void:
	if not spawner_enabled:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
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

func force_spawn_enemy() -> bool:
	if RunQuery.is_gameplay_blocked(get_tree()):
		return false

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

	var packed_enemy: PackedScene = load(enemy_scene_path) as PackedScene

	if packed_enemy == null:
		push_warning("[EnemySpawner] Não foi possível carregar enemy_scene_path: %s" % enemy_scene_path)
		return false

	var enemy_instance: Node = packed_enemy.instantiate()

	if not enemy_instance is Node2D:
		push_warning("[EnemySpawner] Enemy scene não é Node2D.")
		enemy_instance.queue_free()
		return false

	var enemy_node: Node2D = enemy_instance as Node2D
	var spawn_position: Vector2 = _get_safe_spawn_position_around_player()
	var distance_to_player: float = spawn_position.distance_to(player_node.global_position)

	enemy_node.position = enemy_root.to_local(spawn_position)

	enemy_root.add_child(enemy_node)

	if enemy_node.has_method("setup"):
		enemy_node.call("setup", enemy_definition, player_node)

	last_spawn_frame = Engine.get_process_frames()

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

func _get_spawn_position_around_player(min_distance: float, max_distance: float) -> Vector2:
	var safe_min_distance: float = max(0.0, min_distance)
	var safe_max_distance: float = max(safe_min_distance, max_distance)

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(safe_min_distance, safe_max_distance)

	return player_node.global_position + Vector2(cos(angle), sin(angle)) * distance

func _get_alive_enemy_count() -> int:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var count: int = 0

	for enemy: Node in enemies:
		if enemy == null:
			continue

		if not is_instance_valid(enemy):
			continue

		count += 1

	return count

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

func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null

func _on_run_finished(_result_payload: RunResultPayload) -> void:
	spawner_enabled = false

	DeveloperAuditLogger.log_spawn(
		"Desativado após fim da run.",
		"EnemySpawner"
	)

func configure_spawner(player: Node2D, root: Node2D) -> void:
	configure_player(player)
	configure_enemy_root(root)
