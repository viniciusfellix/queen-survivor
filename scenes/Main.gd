## Cena/root principal do jogo.
##
## Responsabilidades:
## - carregar a cena inicial configurada;
## - instanciar essa cena dentro de CurrentSceneRoot;
## - registrar carregamento no logger técnico.
##
## Importante:
## Este script não gerencia gameplay diretamente.
## Ele apenas monta a primeira cena.
extends Node

## Cena inicial carregada ao iniciar o jogo.
@export_file("*.tscn") var initial_scene_path: String = "res://scenes/run/RunScene.tscn"

## Root onde a cena carregada será instanciada.
@onready var current_scene_root: Node = $CurrentSceneRoot

## Carrega a cena inicial quando Main entra na árvore.
func _ready() -> void:
	_load_initial_scene()

## Carrega e instancia a cena inicial configurada.
func _load_initial_scene() -> void:
	if initial_scene_path.strip_edges() == "":
		push_error("[Main] initial_scene_path vazio.")
		return

	var packed_scene := load(initial_scene_path) as PackedScene

	if packed_scene == null:
		push_error("[Main] Não foi possível carregar: %s" % initial_scene_path)
		return

	var scene_instance := packed_scene.instantiate()
	current_scene_root.add_child(scene_instance)

	DeveloperAuditLogger.log_scene(
		"Cena inicial carregada: %s" % initial_scene_path,
		"Main",
		{
			"scene_path": initial_scene_path
		}
	)
