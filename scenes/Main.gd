extends Node

@export_file("*.tscn") var initial_scene_path: String = "res://gameplay/test/TestGaiaScene.tscn"

@onready var current_scene_root: Node = $CurrentSceneRoot

func _ready() -> void:
	_load_initial_scene()

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
