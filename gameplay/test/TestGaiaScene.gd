extends Node2D

@export_file("*.tscn") var player_scene_path: String = "res://gameplay/player/PlayerGaia.tscn"

@onready var arena_root: Node2D = $ArenaRoot
@onready var runtime_root: Node2D = $RuntimeRoot

@onready var player_root: Node2D = $RuntimeRoot/PlayerRoot
@onready var enemy_root: Node2D = $RuntimeRoot/EnemyRoot
@onready var drop_root: Node2D = $RuntimeRoot/DropRoot
@onready var spawner_root: Node2D = $RuntimeRoot/SpawnerRoot
@onready var run_controller: Node = $RuntimeRoot/RunController
@onready var drop_controller: Node = $RuntimeRoot/DropController

@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint
@onready var camera_2d: Camera2D = $Camera2D

var player_instance: Node2D = null

func _ready() -> void:
	_validate_scene_structure()
	_spawn_player()
	_setup_camera_target()
	_configure_spawners()

	GameEvents.emit_debug("[TestGaiaScene] Cena de teste carregada.")

func get_player_instance() -> Node2D:
	return player_instance

func get_enemy_root() -> Node2D:
	return enemy_root

func get_drop_root() -> Node2D:
	return drop_root

func get_arena_root() -> Node2D:
	return arena_root

func get_spawner_root() -> Node2D:
	return spawner_root
	
func get_run_controller() -> Node:
	return run_controller

func get_drop_controller() -> Node:
	return drop_controller
	
func _spawn_player() -> void:
	var packed_player: PackedScene = load(player_scene_path) as PackedScene

	if packed_player == null:
		push_warning("[TestGaiaScene] PlayerGaia não encontrado: %s" % player_scene_path)
		return

	player_instance = packed_player.instantiate() as Node2D

	if player_instance == null:
		push_error("[TestGaiaScene] A cena do player não é Node2D.")
		return

	player_root.add_child(player_instance)
	player_instance.global_position = player_spawn_point.global_position

	GameEvents.emit_debug("[TestGaiaScene] Player instanciado: %s" % player_scene_path)

func _setup_camera_target() -> void:
	if camera_2d == null:
		push_warning("[TestGaiaScene] Camera2D não encontrada.")
		return

	camera_2d.enabled = true
	camera_2d.make_current()

	if player_instance == null:
		return

	if camera_2d.has_method("set_target"):
		camera_2d.call("set_target", player_instance)
	else:
		camera_2d.global_position = player_instance.global_position

func _configure_spawners() -> void:
	if spawner_root == null:
		push_warning("[TestGaiaScene] SpawnerRoot não encontrado.")
		return

	if player_instance == null:
		push_warning("[TestGaiaScene] Não é possível configurar spawners sem player_instance.")
		return

	if enemy_root == null:
		push_warning("[TestGaiaScene] Não é possível configurar spawners sem EnemyRoot.")
		return

	var configured_count: int = 0

	for child: Node in spawner_root.get_children():
		if not child.has_method("configure_spawner"):
			continue

		child.call("configure_spawner", player_instance, enemy_root)
		configured_count += 1

	GameEvents.emit_debug("[TestGaiaScene] Spawners configurados: %s" % str(configured_count))
	
func _validate_scene_structure() -> void:
	if arena_root == null:
		push_warning("[TestGaiaScene] ArenaRoot não encontrado.")

	if runtime_root == null:
		push_warning("[TestGaiaScene] RuntimeRoot não encontrado.")

	if player_root == null:
		push_warning("[TestGaiaScene] PlayerRoot não encontrado.")

	if enemy_root == null:
		push_warning("[TestGaiaScene] EnemyRoot não encontrado.")

	if drop_root == null:
		push_warning("[TestGaiaScene] DropRoot não encontrado.")

	if spawner_root == null:
		push_warning("[TestGaiaScene] SpawnerRoot não encontrado.")

	if player_spawn_point == null:
		push_warning("[TestGaiaScene] PlayerSpawnPoint não encontrado.")

	if camera_2d == null:
		push_warning("[TestGaiaScene] Camera2D não encontrada.")
	
	if run_controller == null:
		push_warning("[TestGaiaScene] RunController não encontrado.")
		
	if drop_controller == null:
		push_warning("[TestGaiaScene] DropController não encontrado.")
