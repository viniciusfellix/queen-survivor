extends Node

@export_file("*.tscn") var floating_text_scene_path: String = "res://ui/world_feedback/FloatingCombatText.tscn"

@export var player_group_name: String = "player"

# Offset em coordenada de mundo antes de converter para tela.
# Ajuste esse valor conforme a altura visual da Gaia.
@export var player_damage_world_offset: Vector2 = Vector2(0.0, -230.0)

# Ajuste final em pixels de tela.
@export var player_damage_screen_offset: Vector2 = Vector2(-90.0, -40.0)

@export var damage_color: Color = Color(1.0, 0.05, 0.05, 1.0)

@export var debug_feedback: bool = true

var feedback_canvas_layer: CanvasLayer = null
var feedback_root: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_feedback_layer()

	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	GameEvents.emit_debug("[WorldFeedbackController] Inicializado. CanvasLayer=%s Root=%s" % [
		str(feedback_canvas_layer != null),
		str(feedback_root != null)
	])

func _on_player_damaged(
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if final_damage <= 0:
		return

	var player_node: Node2D = _get_player()

	if player_node == null:
		GameEvents.emit_debug("[WorldFeedbackController] Não criou floating damage: player ausente.")
		return

	var world_position: Vector2 = player_node.global_position + player_damage_world_offset

	spawn_floating_text(
		"-%s" % str(final_damage),
		world_position,
		damage_color
	)

func spawn_floating_text(text: String, world_position: Vector2, color: Color) -> void:
	if feedback_root == null:
		_create_feedback_layer()

	if feedback_root == null:
		GameEvents.emit_debug("[WorldFeedbackController] Não criou floating damage: feedback_root ausente.")
		return

	var packed_scene: PackedScene = load(floating_text_scene_path) as PackedScene

	if packed_scene == null:
		push_warning("[WorldFeedbackController] Não foi possível carregar FloatingCombatText: %s" % floating_text_scene_path)
		return

	var instance: Node = packed_scene.instantiate()

	if not instance is Control:
		push_warning("[WorldFeedbackController] FloatingCombatText precisa ter root Control/Label.")
		instance.queue_free()
		return

	var text_control: Control = instance as Control
	feedback_root.add_child(text_control)

	var screen_position: Vector2 = _world_to_screen_position(world_position)

	text_control.position = screen_position + player_damage_screen_offset

	if text_control.has_method("setup"):
		text_control.call("setup", text, color)

	if debug_feedback:
		GameEvents.emit_debug("[WorldFeedbackController] Floating damage criado: %s world=%s screen=%s" % [
			text,
			str(world_position),
			str(screen_position)
		])

func _create_feedback_layer() -> void:
	if feedback_canvas_layer != null and is_instance_valid(feedback_canvas_layer):
		return

	feedback_canvas_layer = CanvasLayer.new()
	feedback_canvas_layer.name = "WorldFeedbackCanvasLayer"
	feedback_canvas_layer.layer = 40
	feedback_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(feedback_canvas_layer)

	feedback_root = Control.new()
	feedback_root.name = "WorldFeedbackRoot"
	feedback_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_root.process_mode = Node.PROCESS_MODE_ALWAYS

	feedback_canvas_layer.add_child(feedback_root)

func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform * world_position

func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
