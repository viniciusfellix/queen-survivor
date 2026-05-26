## Cena raiz inicial da aplicação.
##
## Responsável por carregar a primeira cena jogável dentro de
## `CurrentSceneRoot`. No protótipo atual, essa cena é a arena de testes
## com a Gaia, inimigos, HUD e ferramentas técnicas.
extends Node

## Caminho da cena que será instanciada ao iniciar a aplicação.
##
## Durante o Módulo 1 aponta para `TestGaiaScene.tscn`.
## Futuramente poderá apontar para menu principal, seleção de mapa
## ou outro fluxo inicial definitivo.
@export_file("*.tscn") var initial_scene_path: String = "res://gameplay/test/TestGaiaScene.tscn"

## Container onde a cena inicial carregada será adicionada em runtime.
@onready var current_scene_root: Node = $CurrentSceneRoot

## Inicia o carregamento da primeira cena assim que `Main` entra na árvore.
func _ready() -> void:
	_load_initial_scene()

## Carrega e instancia a cena configurada em `initial_scene_path`.
##
## Em caso de caminho vazio ou resource inválido, interrompe o processo
## e emite erro estrutural, pois não existe gameplay sem uma cena inicial.
##
## Ao concluir, registra no canal SCENE qual cena foi instanciada.
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
