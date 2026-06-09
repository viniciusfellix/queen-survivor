## Spawner de inimigos da arena.
##
## Responsabilidades:
## - resolver player e EnemyRoot;
## - usar SpawnTimelineDefinition do mapa quando configurado;
## - sortear ranges runtime de waves uma vez por run;
## - processar multiplas waves ativas;
## - processar multiplas regras por wave;
## - instanciar inimigos fora da tela/ao redor do player;
## - configurar EnemyDefinition no EnemyBase;
## - respeitar limites globais, probabilidade e delays.
##
## O spawner cria inimigos, mas nao controla comportamento de combate diretamente.
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
@export var log_spawn_distance: bool = false

@export_group("Timeline")
@export var use_map_spawn_timeline: bool = true
@export var spawn_timeline_definition: SpawnTimelineDefinition
@export var log_timeline_changes: bool = false

@export_group("Pooling")
@export var prewarm_pool_count: int = 24

var player_node: Node2D = null
var enemy_root: Node2D = null
var spawn_timer: float = 0.0
var active_entry_id: String = ""
var elapsed_since_ready: float = 0.0
var last_spawn_frame: int = -1
var initial_spawn_delay_completed: bool = false
var _alive_enemy_count: int = 0

## Runtime state por wave.
##
## Estrutura:
## {
##   "start_time_seconds": float,
##   "end_time_seconds": float,
##   "activated_once": bool
## }
var _entry_runtime_by_id: Dictionary = {}

## Runtime state por rule.
##
## Estrutura:
## {
##   "activated_once": bool,
##   "next_spawn_time_seconds": float,
##   "total_spawned": int,
##   "alive_count": int
## }
var _rule_runtime_by_key: Dictionary = {}

var _timeline_runtime_initialized: bool = false

func _ready() -> void:
	enemy_root = _resolve_enemy_root()
	player_node = _resolve_player()
	_resolve_spawn_timeline_from_map()
	_initialize_timeline_runtime_if_needed()

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

	_resolve_spawn_timeline_from_map()
	_initialize_timeline_runtime_if_needed()

	if elapsed_since_ready < initial_spawn_delay_seconds:
		return

	if not initial_spawn_delay_completed:
		initial_spawn_delay_completed = true
		spawn_timer = min(spawn_timer, 0.05)

		DeveloperAuditLogger.log_spawn(
			"Delay inicial concluido. Spawner liberado.",
			"EnemySpawner"
		)

	if _timeline_runtime_initialized and spawn_timeline_definition != null:
		_process_timeline_spawn_runtime()
		return

	_process_fallback_spawn(delta)

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

## Mantido como compatibilidade para testes/ferramentas.
func force_spawn_enemy() -> bool:
	return _spawn_enemy_with_config(
		enemy_scene_path,
		enemy_definition,
		spawn_min_distance,
		spawn_max_distance,
		"fallback"
	)

func _process_fallback_spawn(delta: float) -> void:
	spawn_timer -= delta

	if spawn_timer > 0.0:
		return

	var spawned: bool = force_spawn_enemy()

	if spawned:
		spawn_timer = spawn_interval_seconds
	else:
		spawn_timer = min(0.5, spawn_interval_seconds)

func _process_timeline_spawn_runtime() -> void:
	var elapsed_seconds: float = _get_run_elapsed_seconds()
	var active_entries: Array[SpawnTimelineEntryDefinition] = _get_runtime_active_entries(elapsed_seconds)

	active_entry_id = _build_active_entry_debug_id(active_entries)

	for entry: SpawnTimelineEntryDefinition in active_entries:
		_process_entry_rules(entry, elapsed_seconds)

func _process_entry_rules(
	entry: SpawnTimelineEntryDefinition,
	elapsed_seconds: float
) -> void:
	if entry == null:
		return

	var entry_runtime: Dictionary = _entry_runtime_by_id.get(entry.id, {})

	if entry_runtime.is_empty():
		return

	var entry_start_seconds: float = float(entry_runtime.get("start_time_seconds", 0.0))
	var wave_elapsed_seconds: float = max(0.0, elapsed_seconds - entry_start_seconds)
	var rules: Array[SpawnRuleDefinition] = entry.get_effective_spawn_rules()

	for spawn_rule: SpawnRuleDefinition in rules:
		if spawn_rule == null:
			continue

		var rule_key: String = _build_rule_runtime_key(entry.id, spawn_rule.id)
		var rule_runtime: Dictionary = _get_or_create_rule_runtime(rule_key)
		var rule_active_now: bool = spawn_rule.is_active_for_wave_elapsed(wave_elapsed_seconds)

		if not rule_active_now:
			continue

		if not bool(rule_runtime.get("activated_once", false)):
			rule_runtime["activated_once"] = true
			rule_runtime["next_spawn_time_seconds"] = (
				elapsed_seconds + _roll_rule_interval_seconds(spawn_rule)
			)
			_rule_runtime_by_key[rule_key] = rule_runtime

			if entry.should_rule_spawn_on_activate(spawn_rule):
				_try_spawn_rule(entry, spawn_rule, rule_key)
			continue

		if _is_rule_exhausted(spawn_rule, rule_runtime):
			continue

		var next_spawn_time_seconds: float = float(
			rule_runtime.get("next_spawn_time_seconds", elapsed_seconds)
		)

		if elapsed_seconds < next_spawn_time_seconds:
			continue

		_try_spawn_rule(entry, spawn_rule, rule_key)

		rule_runtime = _get_or_create_rule_runtime(rule_key)
		rule_runtime["next_spawn_time_seconds"] = (
			elapsed_seconds + _roll_rule_interval_seconds(spawn_rule)
		)
		_rule_runtime_by_key[rule_key] = rule_runtime

func _try_spawn_rule(
	entry: SpawnTimelineEntryDefinition,
	spawn_rule: SpawnRuleDefinition,
	rule_key: String
) -> bool:
	if not spawner_enabled:
		return false

	if not _can_attempt_spawn_this_frame():
		return false

	if player_node == null:
		player_node = _resolve_player()

	if enemy_root == null:
		enemy_root = _resolve_enemy_root()

	if player_node == null or enemy_root == null:
		return false

	var active_entries: Array[SpawnTimelineEntryDefinition] = _get_runtime_active_entries(
		_get_run_elapsed_seconds()
	)
	var effective_global_max_alive: int = _get_effective_global_max_alive(active_entries)

	if _get_alive_enemy_count() >= effective_global_max_alive:
		return false

	var rule_runtime: Dictionary = _get_or_create_rule_runtime(rule_key)

	if _is_rule_exhausted(spawn_rule, rule_runtime):
		return false

	if spawn_rule.max_alive > 0 and int(rule_runtime.get("alive_count", 0)) >= spawn_rule.max_alive:
		return false

	if not _passes_spawn_probability(spawn_rule):
		return false

	var spawned: bool = _spawn_enemy_with_config(
		spawn_rule.enemy_scene_path,
		spawn_rule.enemy_definition,
		entry.spawn_min_distance,
		entry.spawn_max_distance,
		rule_key
	)

	if not spawned:
		return false

	rule_runtime["total_spawned"] = int(rule_runtime.get("total_spawned", 0)) + 1
	rule_runtime["alive_count"] = int(rule_runtime.get("alive_count", 0)) + 1
	_rule_runtime_by_key[rule_key] = rule_runtime

	return true

func _spawn_enemy_with_config(
	scene_path: String,
	definition: EnemyDefinition,
	min_distance: float,
	max_distance: float,
	rule_key: String
) -> bool:
	if prevent_multiple_spawns_same_frame:
		last_spawn_frame = Engine.get_process_frames()

	if definition == null:
		push_warning("[EnemySpawner] Spawn cancelado: EnemyDefinition ausente.")
		return false

	if scene_path.strip_edges() == "":
		push_warning("[EnemySpawner] Spawn cancelado: enemy_scene_path vazio.")
		return false

	var spawn_position: Vector2 = _get_safe_spawn_position_around_player(
		min_distance,
		max_distance
	)
	var enemy_instance: Node = PoolManager.spawn_path(scene_path, enemy_root, spawn_position)

	if not enemy_instance is Node2D:
		push_warning("[EnemySpawner] Enemy scene invalida ou nao e Node2D: %s" % scene_path)

		if enemy_instance != null:
			PoolManager.despawn(enemy_instance)

		return false

	var enemy_node: Node2D = enemy_instance as Node2D

	if enemy_node.has_method("setup"):
		enemy_node.call("setup", definition, player_node)

	if not enemy_node.tree_exited.is_connected(_on_spawned_enemy_tree_exited.bind(rule_key)):
		enemy_node.tree_exited.connect(
			_on_spawned_enemy_tree_exited.bind(rule_key),
			CONNECT_ONE_SHOT
		)

	_alive_enemy_count += 1

	if log_spawn_distance:
		var distance_to_player: float = enemy_node.global_position.distance_to(player_node.global_position)

		DeveloperAuditLogger.log_spawn(
			"Inimigo criado em: %s | dist_player=%s | vivos=%s | wave=%s | rule=%s" % [
				str(enemy_node.global_position),
				str(distance_to_player),
				str(_get_alive_enemy_count()),
				active_entry_id,
				rule_key
			],
			"EnemySpawner",
			{
				"position": enemy_node.global_position,
				"distance_to_player": distance_to_player,
				"alive_count": _get_alive_enemy_count(),
				"wave_id": active_entry_id,
				"rule_key": rule_key
			}
		)

	return true

func _can_attempt_spawn_this_frame() -> bool:
	if not prevent_multiple_spawns_same_frame:
		return true

	var current_frame: int = Engine.get_process_frames()

	return current_frame != last_spawn_frame

func _passes_spawn_probability(spawn_rule: SpawnRuleDefinition) -> bool:
	if spawn_rule == null:
		return false

	if spawn_rule.spawn_probability_percent >= 100.0:
		return true

	if spawn_rule.spawn_probability_percent <= 0.0:
		return false

	return randf_range(0.0, 100.0) <= spawn_rule.spawn_probability_percent

func _is_rule_exhausted(
	spawn_rule: SpawnRuleDefinition,
	rule_runtime: Dictionary
) -> bool:
	if spawn_rule == null:
		return true

	if spawn_rule.max_total_spawns <= 0:
		return false

	return int(rule_runtime.get("total_spawned", 0)) >= spawn_rule.max_total_spawns

func _roll_rule_interval_seconds(spawn_rule: SpawnRuleDefinition) -> float:
	if spawn_rule == null:
		return max(0.05, spawn_interval_seconds)

	var min_seconds: float = spawn_rule.get_effective_spawn_interval_min_seconds()
	var max_seconds: float = spawn_rule.get_effective_spawn_interval_max_seconds()

	if is_equal_approx(min_seconds, max_seconds):
		return min_seconds

	return randf_range(min_seconds, max_seconds)

func _initialize_timeline_runtime_if_needed() -> void:
	if _timeline_runtime_initialized:
		return

	if spawn_timeline_definition == null:
		return

	_entry_runtime_by_id.clear()
	_rule_runtime_by_key.clear()

	for entry: SpawnTimelineEntryDefinition in spawn_timeline_definition.entries:
		if entry == null:
			continue

		if not entry.is_valid_entry():
			continue

		var runtime_start_seconds: float = _roll_entry_start_time_seconds(entry)
		var runtime_end_seconds: float = _roll_entry_end_time_seconds(entry, runtime_start_seconds)

		_entry_runtime_by_id[entry.id] = {
			"start_time_seconds": runtime_start_seconds,
			"end_time_seconds": runtime_end_seconds,
			"activated_once": false
		}

		for spawn_rule: SpawnRuleDefinition in entry.get_effective_spawn_rules():
			if spawn_rule == null:
				continue

			var rule_key: String = _build_rule_runtime_key(entry.id, spawn_rule.id)
			_rule_runtime_by_key[rule_key] = {
				"activated_once": false,
				"next_spawn_time_seconds": runtime_start_seconds,
				"total_spawned": 0,
				"alive_count": 0
			}

		if log_timeline_changes:
			DeveloperAuditLogger.log_spawn(
				"Wave runtime preparada: %s | start=%s end=%s concurrent=%s rules=%s" % [
					entry.id,
					str(runtime_start_seconds),
					str(runtime_end_seconds),
					str(entry.allow_concurrent),
					str(entry.get_effective_spawn_rules().size())
				],
				"EnemySpawner",
				{
					"wave_id": entry.id,
					"start_time_seconds": runtime_start_seconds,
					"end_time_seconds": runtime_end_seconds,
					"allow_concurrent": entry.allow_concurrent,
					"rules_count": entry.get_effective_spawn_rules().size()
				}
			)

	_timeline_runtime_initialized = true

func _roll_entry_start_time_seconds(entry: SpawnTimelineEntryDefinition) -> float:
	var min_seconds: float = entry.get_effective_start_time_min_seconds()
	var max_seconds: float = entry.get_effective_start_time_max_seconds()

	if is_equal_approx(min_seconds, max_seconds):
		return min_seconds

	return randf_range(min_seconds, max_seconds)

func _roll_entry_end_time_seconds(
	entry: SpawnTimelineEntryDefinition,
	runtime_start_seconds: float
) -> float:
	var min_seconds: float = max(
		runtime_start_seconds,
		entry.get_effective_end_time_min_seconds()
	)
	var max_seconds: float = max(
		min_seconds,
		entry.get_effective_end_time_max_seconds()
	)

	if is_equal_approx(min_seconds, max_seconds):
		return min_seconds

	return randf_range(min_seconds, max_seconds)

func _get_runtime_active_entries(elapsed_seconds: float) -> Array[SpawnTimelineEntryDefinition]:
	var concurrent_entries: Array[SpawnTimelineEntryDefinition] = []
	var exclusive_entries: Array[SpawnTimelineEntryDefinition] = []

	if spawn_timeline_definition == null:
		return concurrent_entries

	for entry: SpawnTimelineEntryDefinition in spawn_timeline_definition.entries:
		if entry == null:
			continue

		if not entry.is_valid_entry():
			continue

		var runtime_data: Dictionary = _entry_runtime_by_id.get(entry.id, {})

		if runtime_data.is_empty():
			continue

		var runtime_start_seconds: float = float(runtime_data.get("start_time_seconds", 0.0))
		var runtime_end_seconds: float = float(runtime_data.get("end_time_seconds", 0.0))

		if elapsed_seconds < runtime_start_seconds or elapsed_seconds >= runtime_end_seconds:
			continue

		if entry.allow_concurrent:
			concurrent_entries.append(entry)
		else:
			exclusive_entries.append(entry)

	var selected_entries: Array[SpawnTimelineEntryDefinition] = concurrent_entries.duplicate()

	if not exclusive_entries.is_empty():
		var selected_exclusive: SpawnTimelineEntryDefinition = exclusive_entries[0]
		var selected_start_seconds: float = float(
			_entry_runtime_by_id[selected_exclusive.id]["start_time_seconds"]
		)

		for entry: SpawnTimelineEntryDefinition in exclusive_entries:
			var entry_start_seconds: float = float(
				_entry_runtime_by_id[entry.id]["start_time_seconds"]
			)

			if entry_start_seconds >= selected_start_seconds:
				selected_exclusive = entry
				selected_start_seconds = entry_start_seconds

		selected_entries.append(selected_exclusive)

	return selected_entries

func _get_effective_global_max_alive(
	active_entries: Array[SpawnTimelineEntryDefinition]
) -> int:
	var effective_max_alive: int = max_alive_enemies

	for entry: SpawnTimelineEntryDefinition in active_entries:
		if entry == null:
			continue

		effective_max_alive = max(effective_max_alive, entry.max_alive_enemies)

	return max(1, effective_max_alive)

func _get_run_elapsed_seconds() -> float:
	var run_state: RunState = RunQuery.get_run_state(get_tree())

	if run_state != null:
		return run_state.elapsed_seconds

	return 0.0

func _build_rule_runtime_key(entry_id: String, rule_id: String) -> String:
	return "%s::%s" % [entry_id, rule_id]

func _build_active_entry_debug_id(
	active_entries: Array[SpawnTimelineEntryDefinition]
) -> String:
	if active_entries.is_empty():
		return ""

	var ids: Array[String] = []

	for entry: SpawnTimelineEntryDefinition in active_entries:
		if entry == null:
			continue

		ids.append(entry.id)

	return ", ".join(ids)

func _get_or_create_rule_runtime(rule_key: String) -> Dictionary:
	if not _rule_runtime_by_key.has(rule_key):
		_rule_runtime_by_key[rule_key] = {
			"activated_once": false,
			"next_spawn_time_seconds": 0.0,
			"total_spawned": 0,
			"alive_count": 0
		}

	return _rule_runtime_by_key[rule_key]

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
			_timeline_runtime_initialized = false

			DeveloperAuditLogger.log_spawn(
				"SpawnTimeline resolvida: %s" % spawn_timeline_definition.id,
				"EnemySpawner",
				{
					"timeline_id": spawn_timeline_definition.id
				}
			)

func _get_safe_spawn_position_around_player(
	min_distance: float,
	max_distance: float
) -> Vector2:
	var safe_min_distance: float = max(minimum_safe_spawn_distance_from_player, min_distance)
	var safe_max_distance: float = max(safe_min_distance + 1.0, max_distance)

	var best_position: Vector2 = player_node.global_position + Vector2.RIGHT * safe_min_distance
	var best_distance: float = 0.0

	for _attempt: int in range(max(1, spawn_position_attempts)):
		var candidate_position: Vector2 = _get_spawn_position_around_player(
			safe_min_distance,
			safe_max_distance
		)
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
	return _alive_enemy_count

func get_debug_data() -> Dictionary:
	var active_entries: Array[SpawnTimelineEntryDefinition] = []
	var active_wave_ids: Array[String] = []
	var active_rule_keys: Array[String] = []
	var total_spawned: int = 0

	if _timeline_runtime_initialized and spawn_timeline_definition != null:
		active_entries = _get_runtime_active_entries(_get_run_elapsed_seconds())

		for entry: SpawnTimelineEntryDefinition in active_entries:
			if entry == null:
				continue

			active_wave_ids.append(entry.id)

		active_rule_keys = _get_runtime_active_rule_keys(
			active_entries,
			_get_run_elapsed_seconds()
		)

	for rule_runtime_variant: Variant in _rule_runtime_by_key.values():
		if not rule_runtime_variant is Dictionary:
			continue

		var rule_runtime: Dictionary = rule_runtime_variant
		total_spawned += int(rule_runtime.get("total_spawned", 0))

	return {
		"spawner_enabled": spawner_enabled,
		"timeline_initialized": _timeline_runtime_initialized,
		"timeline_id": (
			spawn_timeline_definition.id
			if spawn_timeline_definition != null
			else ""
		),
		"active_entry_id": active_entry_id,
		"active_wave_ids": active_wave_ids,
		"active_wave_count": active_wave_ids.size(),
		"active_rule_keys": active_rule_keys,
		"active_rule_count": active_rule_keys.size(),
		"tracked_rule_count": _rule_runtime_by_key.size(),
		"total_spawned": total_spawned,
		"alive_enemy_count": _alive_enemy_count,
		"effective_global_max_alive": _get_effective_global_max_alive(active_entries)
	}

func _get_runtime_active_rule_keys(
	active_entries: Array[SpawnTimelineEntryDefinition],
	elapsed_seconds: float
) -> Array[String]:
	var active_rule_keys: Array[String] = []

	for entry: SpawnTimelineEntryDefinition in active_entries:
		if entry == null:
			continue

		var entry_runtime: Dictionary = _entry_runtime_by_id.get(entry.id, {})

		if entry_runtime.is_empty():
			continue

		var entry_start_seconds: float = float(entry_runtime.get("start_time_seconds", 0.0))
		var wave_elapsed_seconds: float = max(0.0, elapsed_seconds - entry_start_seconds)

		for spawn_rule: SpawnRuleDefinition in entry.get_effective_spawn_rules():
			if spawn_rule == null:
				continue

			if not spawn_rule.is_active_for_wave_elapsed(wave_elapsed_seconds):
				continue

			active_rule_keys.append(_build_rule_runtime_key(entry.id, spawn_rule.id))

	return active_rule_keys

func _on_enemy_died_count(
	_enemy_id: String,
	_source_id: String,
	_xp_reward: int,
	_enemy_global_position: Vector2,
	_coin_drop_chance: float,
	_coin_drop_value: int
) -> void:
	_alive_enemy_count = max(0, _alive_enemy_count - 1)

func _on_spawned_enemy_tree_exited(rule_key: String) -> void:
	if rule_key.strip_edges() == "":
		return

	var rule_runtime: Dictionary = _get_or_create_rule_runtime(rule_key)
	rule_runtime["alive_count"] = max(0, int(rule_runtime.get("alive_count", 0)) - 1)
	_rule_runtime_by_key[rule_key] = rule_runtime

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
		"Desativado apos fim da run.",
		"EnemySpawner"
	)

func configure_spawner(player: Node2D, root: Node2D) -> void:
	configure_player(player)
	configure_enemy_root(root)
