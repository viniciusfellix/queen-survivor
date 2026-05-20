extends Node2D

@export var spawner_enabled: bool = true

@export_file("*.tscn") var enemy_scene_path: String = "res://gameplay/enemies/EnemyBase.tscn"
@export var enemy_definition: EnemyDefinition

@export var enemy_root_path: NodePath
@export var player_group_name: String = "player"
@export var enemy_group_name: String = "enemy"

@export var spawn_interval_seconds: float = 1.5
@export var spawn_distance_min: float = 420.0
@export var spawn_distance_max: float = 620.0

@export var max_alive_enemies: int = 20
@export var spawn_on_ready: bool = false

var spawn_timer: float = 0.0

var enemy_root: Node2D = null
var player_node: Node2D = null
var is_configured_by_scene: bool = false

func _ready() -> void:
	randomize()

	enemy_root = _resolve_enemy_root()
	player_node = _resolve_player()

	if enemy_root == null:
		GameEvents.emit_debug("[EnemySpawner] EnemyRoot não encontrado no _ready().")
	else:
		GameEvents.emit_debug("[EnemySpawner] EnemyRoot encontrado: %s" % enemy_root.name)

	if player_node == null:
		GameEvents.emit_debug("[EnemySpawner] Player não encontrado no _ready(). A cena pode configurar depois.")
	else:
		GameEvents.emit_debug("[EnemySpawner] Player encontrado no _ready(): %s" % player_node.name)

	if spawn_on_ready:
		force_spawn_enemy()

func _process(delta: float) -> void:
	if not spawner_enabled:
		return

	if player_node == null:
		player_node = _resolve_player()

	if enemy_root == null:
		enemy_root = _resolve_enemy_root()

	if player_node == null or enemy_root == null:
		return

	spawn_timer += delta

	if spawn_timer >= spawn_interval_seconds:
		spawn_timer = 0.0
		force_spawn_enemy()

func configure_spawner(new_player: Node2D, new_enemy_root: Node2D) -> void:
	player_node = new_player
	enemy_root = new_enemy_root
	is_configured_by_scene = true
	spawn_timer = 0.0

	if player_node != null:
		GameEvents.emit_debug("[EnemySpawner] Player configurado pela cena: %s" % player_node.name)
	else:
		GameEvents.emit_debug("[EnemySpawner] Player configurado pela cena está null.")

	if enemy_root != null:
		GameEvents.emit_debug("[EnemySpawner] EnemyRoot configurado pela cena: %s" % enemy_root.name)
	else:
		GameEvents.emit_debug("[EnemySpawner] EnemyRoot configurado pela cena está null.")

func force_spawn_enemy() -> void:
	GameEvents.emit_debug("[EnemySpawner] Tentando criar inimigo...")

	if not spawner_enabled:
		GameEvents.emit_debug("[EnemySpawner] Spawn cancelado: spawner desativado.")
		return

	if player_node == null:
		player_node = _resolve_player()

	if enemy_root == null:
		enemy_root = _resolve_enemy_root()

	if player_node == null:
		GameEvents.emit_debug("[EnemySpawner] Spawn cancelado: player_node null.")
		return

	if enemy_root == null:
		GameEvents.emit_debug("[EnemySpawner] Spawn cancelado: enemy_root null.")
		return

	var alive_count: int = _get_alive_enemy_count()

	if alive_count >= max_alive_enemies:
		GameEvents.emit_debug("[EnemySpawner] Spawn cancelado: limite atingido. vivos=%s / max=%s" % [
			str(alive_count),
			str(max_alive_enemies)
		])
		return

	var packed_enemy: PackedScene = load(enemy_scene_path) as PackedScene

	if packed_enemy == null:
		push_warning("[EnemySpawner] Não foi possível carregar enemy_scene_path: %s" % enemy_scene_path)
		return

	var enemy_instance: Node = packed_enemy.instantiate()

	if not enemy_instance is Node2D:
		push_warning("[EnemySpawner] Enemy scene não é Node2D.")
		enemy_instance.queue_free()
		return

	var enemy_node: Node2D = enemy_instance as Node2D

	enemy_root.add_child(enemy_node)
	enemy_node.global_position = _get_spawn_position_around_player()

	if enemy_node.has_method("setup"):
		enemy_node.call("setup", enemy_definition, player_node)
	else:
		GameEvents.emit_debug("[EnemySpawner] Enemy criado, mas não possui método setup().")

	GameEvents.emit_debug("[EnemySpawner] Inimigo criado em: %s | vivos=%s" % [
		str(enemy_node.global_position),
		str(alive_count + 1)
	])

func _get_spawn_position_around_player() -> Vector2:
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(spawn_distance_min, spawn_distance_max)
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance

	return player_node.global_position + offset

func _get_alive_enemy_count() -> int:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(enemy_group_name)
	var count: int = 0

	for enemy: Node in enemies:
		if enemy != null and is_instance_valid(enemy):
			count += 1

	return count

func _resolve_enemy_root() -> Node2D:
	if enemy_root_path != NodePath():
		var configured_root: Node = get_node_or_null(enemy_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var parent_node: Node = get_parent()

	if parent_node != null:
		var sibling_root: Node = parent_node.get_node_or_null("EnemyRoot")

		if sibling_root is Node2D:
			return sibling_root as Node2D

		var parent_parent: Node = parent_node.get_parent()

		if parent_parent != null:
			var uncle_root: Node = parent_parent.get_node_or_null("EnemyRoot")

			if uncle_root is Node2D:
				return uncle_root as Node2D

	return null

func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
