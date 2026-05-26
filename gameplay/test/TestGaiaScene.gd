## Cena jogável de integração do Módulo 1.
##
## Reúne a arena infinita de teste, Gaia, inimigos, drops, câmera,
## controlador da run e interfaces do protótipo.
##
## Esta cena é responsável apenas por montar e conectar os sistemas
## principais. Regras de combate, progressão, spawn e recompensas
## permanecem em seus respectivos controllers e resources.
extends Node2D

## Cena do player que será instanciada ao iniciar o mapa.
##
## Atualmente utiliza a Gaia como primeira Queen jogável do protótipo.
@export_file("*.tscn") var player_scene_path: String = "res://gameplay/player/PlayerGaia.tscn"

## Container visual da arena/mapa.
@onready var arena_root: Node2D = $ArenaRoot

## Container dos sistemas e entidades gerados durante a execução.
@onready var runtime_root: Node2D = $RuntimeRoot

## Container onde a Queen será instanciada.
@onready var player_root: Node2D = $RuntimeRoot/PlayerRoot

## Container onde inimigos criados pelo spawner serão adicionados.
@onready var enemy_root: Node2D = $RuntimeRoot/EnemyRoot

## Container onde moedas e futuros drops físicos serão adicionados.
@onready var drop_root: Node2D = $RuntimeRoot/DropRoot

## Container que reúne os spawners ativos do mapa.
@onready var spawner_root: Node2D = $RuntimeRoot/SpawnerRoot

## Controlador central da run atual.
@onready var run_controller: Node = $RuntimeRoot/RunController

## Controlador responsável pela criação de moedas após mortes de inimigos.
@onready var drop_controller: Node = $RuntimeRoot/DropController

## Posição inicial onde a Queen será colocada ao começar a run.
@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint

## Câmera principal utilizada durante o gameplay.
@onready var camera_2d: Camera2D = $Camera2D

## Referência runtime da Queen instanciada nesta cena.
var player_instance: Node2D = null

## Monta a cena jogável em ordem segura:
## 1. valida a estrutura mínima salva no editor;
## 2. instancia a Queen;
## 3. conecta a câmera ao player;
## 4. injeta player e EnemyRoot nos spawners.
func _ready() -> void:
	_validate_scene_structure()
	_spawn_player()
	_setup_camera_target()
	_configure_spawners()

	DeveloperAuditLogger.log_scene(
		"Cena de teste carregada.",
		"TestGaiaScene"
	)

## Retorna a instância atual da Queen criada para a run.
##
## Usado por sistemas que precisam localizar diretamente o player
## sem depender apenas do grupo global `player`.
func get_player_instance() -> Node2D:
	return player_instance

## Retorna o container onde inimigos da run são adicionados.
func get_enemy_root() -> Node2D:
	return enemy_root

## Retorna o container onde drops físicos da run são adicionados.
func get_drop_root() -> Node2D:
	return drop_root

## Retorna o controlador principal da run presente na cena.
func get_run_controller() -> Node:
	return run_controller

## Instancia a cena configurada para o player e a posiciona no ponto inicial.
##
## A ausência da cena ou a instanciação de um tipo incompatível representa
## erro estrutural, pois impede a execução correta do protótipo.
func _spawn_player() -> void:
	var packed_player: PackedScene = load(player_scene_path) as PackedScene

	if packed_player == null:
		push_error("[TestGaiaScene] PlayerGaia não encontrado: %s" % player_scene_path)
		return

	player_instance = packed_player.instantiate() as Node2D

	if player_instance == null:
		push_error("[TestGaiaScene] A cena do player não é Node2D.")
		return

	player_root.add_child(player_instance)
	player_instance.global_position = player_spawn_point.global_position

	DeveloperAuditLogger.log_scene(
		"Player instanciado: %s" % player_instance.name,
		"TestGaiaScene",
		{
			"player_name": player_instance.name,
			"scene_file_path": player_instance.scene_file_path
		}
	)

## Define a Queen como alvo da câmera principal.
##
## Quando a câmera possui o método `set_target`, utiliza o comportamento
## completo de acompanhamento. Caso contrário, posiciona a câmera diretamente
## sobre o player como fallback simples.
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

## Configura todos os spawners encontrados em `SpawnerRoot`.
##
## Cada spawner compatível recebe:
## - a instância atual do player, utilizada como referência de spawn e perseguição;
## - o EnemyRoot, utilizado como container dos inimigos criados.
func _configure_spawners() -> void:
	if spawner_root == null:
		push_error("[TestGaiaScene] SpawnerRoot não encontrado.")
		return

	if player_instance == null:
		push_error("[TestGaiaScene] Não é possível configurar spawners sem player_instance.")
		return

	if enemy_root == null:
		push_error("[TestGaiaScene] Não é possível configurar spawners sem EnemyRoot.")
		return

	var configured_count: int = 0

	for child: Node in spawner_root.get_children():
		if not child.has_method("configure_spawner"):
			continue

		child.call("configure_spawner", player_instance, enemy_root)
		configured_count += 1

	DeveloperAuditLogger.log_scene(
		"Spawners configurados: %s" % str(configured_count),
		"TestGaiaScene",
		{
			"configured_count": configured_count
		}
	)

## Verifica se os nodes esperados da cena foram mantidos no editor.
##
## Esta validação auxilia manutenção da árvore da cena e informa rapidamente
## quando algum container obrigatório foi removido ou renomeado.
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
