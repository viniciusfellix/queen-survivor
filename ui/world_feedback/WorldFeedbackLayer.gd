extends CanvasLayer

@export_group("Scene")
@export var floating_combat_text_scene: PackedScene

@export_group("Player Damage")
@export var player_group_name: String = "player"

# A arte Spine da Gaia é alta; este offset coloca o número acima da cabeça.
@export var player_damage_world_offset: Vector2 = Vector2(0.0, -285.0)

@export var damage_color: Color = Color(1.0, 0.04, 0.04, 1.0)

@export_group("Debug")
@export var debug_feedback: bool = true

# Ative temporariamente para testar o render sem precisar receber dano.
@export var show_test_text_on_ready: bool = false

@onready var feedback_root: Control = $FeedbackRoot

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 18

	_configure_feedback_root()

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	GameEvents.emit_debug("[WorldFeedbackLayer] Inicializado. root=%s scene=%s" % [
		str(feedback_root != null),
		str(floating_combat_text_scene != null)
	])

	if show_test_text_on_ready:
		call_deferred("_spawn_debug_test_text")

func _on_viewport_size_changed() -> void:
	_configure_feedback_root()

func _configure_feedback_root() -> void:
	if feedback_root == null:
		return

	feedback_root.position = Vector2.ZERO
	feedback_root.size = get_viewport().get_visible_rect().size
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_root.clip_contents = false
	feedback_root.process_mode = Node.PROCESS_MODE_ALWAYS

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
		GameEvents.emit_debug("[WorldFeedbackLayer] Floating damage cancelado: player não encontrado.")
		return

	var world_position: Vector2 = player_node.global_position + player_damage_world_offset
	var screen_position: Vector2 = _world_to_screen_position(world_position)

	spawn_floating_text("-%s" % str(final_damage), screen_position, damage_color)

func spawn_floating_text(display_text: String, screen_position: Vector2, color: Color) -> void:
	if feedback_root == null:
		GameEvents.emit_debug("[WorldFeedbackLayer] Floating damage cancelado: FeedbackRoot ausente.")
		return

	if floating_combat_text_scene == null:
		push_warning("[WorldFeedbackLayer] FloatingCombatText scene não configurada.")
		return

	var instance: Node = floating_combat_text_scene.instantiate()

	if not instance is Control:
		push_warning("[WorldFeedbackLayer] FloatingCombatText precisa ter root do tipo Control ou Label.")
		instance.queue_free()
		return

	var text_control: Control = instance as Control

	feedback_root.add_child(text_control)

	# O texto centraliza sobre a posição calculada.
	text_control.position = screen_position - (text_control.size * 0.5)
	text_control.visible = true

	if text_control.has_method("setup"):
		text_control.call("setup", display_text, color)

	if debug_feedback:
		GameEvents.emit_debug("[WorldFeedbackLayer] Floating damage exibido: text=%s screen=%s final_pos=%s" % [
			display_text,
			str(screen_position),
			str(text_control.position)
		])

func _spawn_debug_test_text() -> void:
	var center_position: Vector2 = get_viewport().get_visible_rect().size * 0.5

	spawn_floating_text(
		"TESTE -6",
		center_position,
		damage_color
	)

func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform * world_position

func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
