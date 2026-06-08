## Cena paralela de runtime preparada para a futura migração da run oficial.
##
## Responsabilidades:
## - espelhar a composição funcional atual da cena de runtime existente;
## - validar a estrutura esperada da cena;
## - instanciar a Gaia no ponto de spawn;
## - configurar câmera;
## - configurar spawners;
## - expor roots e controllers para testes/debug.
##
## Importante:
## Esta cena ainda não substitui a runtime oficial atual.
## Ela existe para preparar uma migração gradual sem alterar o fluxo carregado
## por Main.gd nesta PR.
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

## Valida estrutura, instancia player, configura câmera e spawners.
func _ready() -> void:
	_validate_scene_structure()
	_spawn_player()
	_setup_camera_target()
	_configure_spawners()

	DeveloperAuditLogger.log_scene(
		"Cena paralela de run carregada.",
		"RunScene"
	)

## Retorna instância atual da Gaia criada pela cena.
func get_player_instance() -> Node2D:
	return player_instance

## Retorna root de inimigos da cena.
func get_enemy_root() -> Node2D:
	return enemy_root

## Retorna root de drops/moedas da cena.
func get_drop_root() -> Node2D:
	return drop_root

## Retorna RunController da cena.
func get_run_controller() -> Node:
	return run_controller

## Instancia PlayerGaia no ponto de spawn configurado.
func _spawn_player() -> void:
	var packed_player: PackedScene = load(player_scene_path) as PackedScene

	if packed_player == null:
		push_error("[RunScene] PlayerGaia não encontrado: %s" % player_scene_path)
		return

	player_instance = packed_player.instantiate() as Node2D

	if player_instance == null:
		push_error("[RunScene] A cena do player não é Node2D.")
		return

	player_root.add_child(player_instance)
	player_instance.global_position = player_spawn_point.global_position

	DeveloperAuditLogger.log_scene(
		"Player instanciado: %s" % player_instance.name,
		"RunScene",
		{
			"player_name": player_instance.name,
			"scene_file_path": player_instance.scene_file_path
		}
	)

## Configura FollowCamera para seguir a Gaia instanciada.
func _setup_camera_target() -> void:
	if camera_2d == null:
		push_warning("[RunScene] Camera2D não encontrada.")
		return

	camera_2d.enabled = true
	camera_2d.make_current()

	if player_instance == null:
		return

	if camera_2d.has_method("set_target"):
		camera_2d.call("set_target", player_instance)
	else:
		camera_2d.global_position = player_instance.global_position

## Entrega player e EnemyRoot aos spawners da cena.
func _configure_spawners() -> void:
	if spawner_root == null:
		push_error("[RunScene] SpawnerRoot não encontrado.")
		return

	if player_instance == null:
		push_error("[RunScene] Não é possível configurar spawners sem player_instance.")
		return

	if enemy_root == null:
		push_error("[RunScene] Não é possível configurar spawners sem EnemyRoot.")
		return

	var configured_count: int = 0

	for child: Node in spawner_root.get_children():
		if not child.has_method("configure_spawner"):
			continue

		child.call("configure_spawner", player_instance, enemy_root)
		configured_count += 1

	DeveloperAuditLogger.log_scene(
		"Spawners configurados: %s" % str(configured_count),
		"RunScene",
		{
			"configured_count": configured_count
		}
	)

## Verifica nodes obrigatórios da cena paralela.
func _validate_scene_structure() -> void:
	if arena_root == null:
		push_warning("[RunScene] ArenaRoot não encontrado.")

	if runtime_root == null:
		push_warning("[RunScene] RuntimeRoot não encontrado.")

	if player_root == null:
		push_warning("[RunScene] PlayerRoot não encontrado.")

	if enemy_root == null:
		push_warning("[RunScene] EnemyRoot não encontrado.")

	if drop_root == null:
		push_warning("[RunScene] DropRoot não encontrado.")

	if spawner_root == null:
		push_warning("[RunScene] SpawnerRoot não encontrado.")

	if player_spawn_point == null:
		push_warning("[RunScene] PlayerSpawnPoint não encontrado.")

	if camera_2d == null:
		push_warning("[RunScene] Camera2D não encontrada.")

	if run_controller == null:
		push_warning("[RunScene] RunController não encontrado.")

	if drop_controller == null:
		push_warning("[RunScene] DropController não encontrado.")
