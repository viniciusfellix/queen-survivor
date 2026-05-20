extends CanvasLayer

@onready var panel: Panel = get_node_or_null("Panel") as Panel
@onready var label: Label = _resolve_label()

var last_animation_name: String = ""

func _ready() -> void:
	_configure_panel()

	if not GameEvents.spine_animation_changed.is_connected(_on_spine_animation_changed):
		GameEvents.spine_animation_changed.connect(_on_spine_animation_changed)

	if label == null:
		GameEvents.emit_debug("[DebugOverlay] Label NÃO encontrado.")
	else:
		GameEvents.emit_debug("[DebugOverlay] Label encontrado: %s" % label.name)

func _process(_delta: float) -> void:
	if label == null:
		label = _resolve_label()

		if label == null:
			return

	var player: Node = _get_player()
	var move_direction: Vector2 = InputManager.get_move_direction()
	var aim_direction: Vector2 = InputManager.get_aim_direction()

	var lines: Array[String] = []

	lines.append(LocalizationManager.get_text("ui.debug.title"))
	lines.append("--------------------")
	lines.append("%s: %s" % [LocalizationManager.get_text("ui.debug.move_direction"), _format_vector(move_direction)])
	lines.append("%s: %s" % [LocalizationManager.get_text("ui.debug.aim_direction"), _format_vector(aim_direction)])
	lines.append("%s: %s" % [LocalizationManager.get_text("ui.debug.animation"), last_animation_name])
	
	var run_controller: Node = _get_run_controller()
	
	if player != null and player.has_method("get_debug_data"):
		var debug_data_variant: Variant = player.call("get_debug_data")
		var data: Dictionary = {}

		if debug_data_variant is Dictionary:
			data = debug_data_variant

		lines.append("--------------------")
		#lines.append("Queen: %s" % str(data.get("queen_id", "-")))
		lines.append("HP: %s / %s" % [str(data.get("current_hp", "-")), str(data.get("max_hp", "-"))])
		lines.append("Defense: %s%%" % str(data.get("defense_percent", "-")))
		#lines.append("Last Damage: %s" % str(data.get("last_damage_taken", 0)))
		#lines.append("Total Damage: %s" % str(data.get("total_damage_taken", 0)))
		#lines.append("Last Source: %s" % str(data.get("last_damage_source_id", "")))
		#lines.append("Death Cause: %s" % str(data.get("death_cause", "")))
		lines.append("State: %s" % str(data.get("current_gameplay_state", "-")))
		lines.append("Visual State: %s" % str(data.get("current_visual_state", "-")))
		lines.append("Moving: %s" % str(data.get("is_moving", false)))
		lines.append("Alive: %s" % str(data.get("is_alive", false)))
		lines.append("Facing: %s" % _format_vector(data.get("facing_direction", Vector2.ZERO)))
		lines.append("Position: %s" % _format_vector(data.get("global_position", Vector2.ZERO)))
		
		if run_controller != null and run_controller.has_method("get_debug_data"):
			var run_debug_variant: Variant = run_controller.call("get_debug_data")
			var run_data: Dictionary = {}

			if run_debug_variant is Dictionary:
				run_data = run_debug_variant

			lines.append("--------------------")
			lines.append("Run Time: %.2f" % float(run_data.get("elapsed_seconds", 0.0)))
			lines.append("Run XP: %s" % str(run_data.get("run_xp_gained", 0)))
			lines.append("Level: %s" % str(run_data.get("current_level", 1)))
			lines.append("Level XP: %s / %s" % [
				str(run_data.get("current_level_xp", 0)),
				str(run_data.get("xp_required_for_next_level", 10))
			])
			lines.append("Enemies Killed: %s" % str(run_data.get("enemies_killed", 0)))
			
			lines.append("Paused: %s" % str(run_data.get("is_paused", false)))
			lines.append("LevelUp Active: %s" % str(run_data.get("is_level_up_active", false)))
			lines.append("Pending LevelUps: %s" % str(run_data.get("pending_level_ups", 0)))
			
			lines.append("Run Coins: %s" % str(run_data.get("run_coins_collected", 0)))
			lines.append("Coins Available: %s" % str(run_data.get("run_coins_available", 0)))
	else:
		lines.append("--------------------")
		lines.append("Player: não encontrado")

	label.text = "\n".join(lines)

func _configure_panel() -> void:
	if panel != null:
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.position = Vector2(16.0, 16.0)
		panel.size = Vector2(600.0, 420.0)
		panel.custom_minimum_size = Vector2(600.0, 420.0)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin_container: MarginContainer = get_node_or_null("Panel/MarginContainer") as MarginContainer

	if margin_container != null:
		margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin_container.offset_left = 8.0
		margin_container.offset_top = 8.0
		margin_container.offset_right = -8.0
		margin_container.offset_bottom = -8.0
		margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if label != null:
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = "DebugOverlay inicializado"

func _resolve_label() -> Label:
	var direct_label: Label = get_node_or_null("Panel/MarginContainer/Label") as Label

	if direct_label != null:
		return direct_label

	var found_label: Label = _find_first_label(self)

	if found_label != null:
		return found_label

	return null

func _find_first_label(root: Node) -> Label:
	if root == null:
		return null

	if root is Label:
		return root as Label

	for child: Node in root.get_children():
		var found: Label = _find_first_label(child)

		if found != null:
			return found

	return null

func _get_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return null

	return players[0]

func _format_vector(value: Variant) -> String:
	if value is Vector2:
		var vector: Vector2 = value
		return "(%.2f, %.2f)" % [vector.x, vector.y]

	return str(value)

func _on_spine_animation_changed(animation_name: String) -> void:
	last_animation_name = animation_name

func _get_run_controller() -> Node:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("run_controller")

	if not nodes.is_empty():
		return nodes[0]

	var current_scene: Node = get_tree().current_scene

	if current_scene != null:
		var found: Node = _find_node_with_method(current_scene, "get_run_state")

		if found != null:
			return found

	return null

func _find_node_with_method(root: Node, method_name: String) -> Node:
	if root == null:
		return null

	if root.has_method(method_name):
		return root

	for child: Node in root.get_children():
		var found: Node = _find_node_with_method(child, method_name)

		if found != null:
			return found

	return null
