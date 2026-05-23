extends CanvasLayer

@export_group("Master")
@export var debug_enabled: bool = true
@export var show_title: bool = true
@export var show_separators: bool = true

@export_group("Panel Layout")
@export var panel_position: Vector2 = Vector2(16.0, 16.0)
@export var panel_size: Vector2 = Vector2(600.0, 420.0)
@export var panel_margin: float = 8.0

@export_group("Sections")
@export var show_input_section: bool = true
@export var show_animation_section: bool = true
@export var show_player_core_section: bool = true
@export var show_player_combat_section: bool = true
@export var show_player_direction_section: bool = false
@export var show_run_timer_section: bool = true
@export var show_run_progression_section: bool = true
@export var show_run_economy_section: bool = true
@export var show_run_result_section: bool = false
@export var show_save_section: bool = false
@export var show_technical_section: bool = false

@export_group("Formatting")
@export var compact_vectors: bool = true
@export var decimal_places: int = 2
@export var max_completed_maps_to_show: int = 3

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
	if panel != null:
		panel.visible = debug_enabled

	if not debug_enabled:
		return

	if label == null:
		label = _resolve_label()

		if label == null:
			return

	var lines: Array[String] = []

	var player: Node = _get_player()
	var player_data: Dictionary = _get_debug_data_from_node(player)

	var run_controller: Node = _get_run_controller()
	var run_data: Dictionary = _get_debug_data_from_node(run_controller)

	var save_data: Dictionary = SaveManager.get_debug_data()

	if show_title:
		lines.append(LocalizationManager.get_text("ui.debug.title"))

	if show_input_section:
		_append_separator(lines)
		_append_input_section(lines)

	if show_animation_section:
		_append_separator(lines)
		_append_animation_section(lines)

	if show_player_core_section:
		_append_separator(lines)
		_append_player_core_section(lines, player_data)

	if show_player_combat_section:
		_append_separator(lines)
		_append_player_combat_section(lines, player_data)

	if show_player_direction_section:
		_append_separator(lines)
		_append_player_direction_section(lines, player_data)

	if show_run_timer_section:
		_append_separator(lines)
		_append_run_timer_section(lines, run_data)

	if show_run_progression_section:
		_append_separator(lines)
		_append_run_progression_section(lines, run_data)

	if show_run_economy_section:
		_append_separator(lines)
		_append_run_economy_section(lines, run_data)

	if show_run_result_section:
		_append_separator(lines)
		_append_run_result_section(lines, run_data)

	if show_save_section:
		_append_separator(lines)
		_append_save_section(lines, save_data)

	if show_technical_section:
		_append_separator(lines)
		_append_technical_section(lines, player_data, run_data, save_data)

	if lines.is_empty():
		lines.append("DebugOverlay ativo, mas todas as seções estão desabilitadas.")

	label.text = "\n".join(lines)

func _append_input_section(lines: Array[String]) -> void:
	var move_direction: Vector2 = InputManager.get_move_direction()
	var aim_direction: Vector2 = InputManager.get_aim_direction()

	lines.append("INPUT")
	lines.append("Move: %s" % _format_vector(move_direction))
	lines.append("Aim: %s" % _format_vector(aim_direction))

func _append_animation_section(lines: Array[String]) -> void:
	lines.append("ANIMATION")
	lines.append("Last Spine: %s" % last_animation_name)

func _append_player_core_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("PLAYER")

	if data.is_empty():
		lines.append("Player: não encontrado")
		return

	lines.append("Queen: %s" % str(data.get("queen_id", "-")))
	lines.append("HP: %s / %s" % [
		str(data.get("current_hp", "-")),
		str(data.get("max_hp", "-"))
	])
	lines.append("Alive: %s" % str(data.get("is_alive", false)))
	lines.append("State: %s" % str(data.get("current_gameplay_state", "-")))
	lines.append("Move Speed: %s" % _format_float(float(data.get("move_speed", 0.0))))

func _append_player_combat_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("PLAYER COMBAT")

	if data.is_empty():
		lines.append("Player: não encontrado")
		return

	lines.append("Defense: %s%%" % _format_float(float(data.get("defense_percent", 0.0))))
	lines.append("Last Damage: %s" % str(data.get("last_damage_taken", 0)))
	lines.append("Total Damage: %s" % str(data.get("total_damage_taken", 0)))
	lines.append("Last Source: %s" % str(data.get("last_damage_source_id", "")))
	lines.append("Death Cause: %s" % str(data.get("death_cause", "")))

func _append_player_direction_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("PLAYER DIRECTIONS")

	if data.is_empty():
		lines.append("Player: não encontrado")
		return

	lines.append("Move Direction: %s" % _format_vector(data.get("move_direction", Vector2.ZERO)))
	lines.append("Aim Direction: %s" % _format_vector(data.get("aim_direction", Vector2.ZERO)))
	lines.append("Last Aim: %s" % _format_vector(data.get("last_valid_aim_direction", Vector2.ZERO)))
	lines.append("Facing: %s" % _format_vector(data.get("facing_direction", Vector2.ZERO)))
	lines.append("Position: %s" % _format_vector(data.get("global_position", Vector2.ZERO)))

func _append_run_timer_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN TIMER")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Map: %s" % str(data.get("map_id", "")))
	lines.append("Time: %s" % _format_seconds(float(data.get("elapsed_seconds", 0.0))))
	lines.append("Remaining: %s" % _format_seconds(float(data.get("remaining_seconds", 0.0))))
	lines.append("Duration: %s" % _format_seconds(float(data.get("map_duration_seconds", 0.0))))

func _append_run_progression_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN PROGRESSION")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Run XP: %s" % str(data.get("run_xp_gained", 0)))
	lines.append("Level: %s" % str(data.get("current_level", 1)))
	lines.append("Level XP: %s / %s" % [
		str(data.get("current_level_xp", 0)),
		str(data.get("xp_required_for_next_level", 10))
	])
	lines.append("Enemies Killed: %s" % str(data.get("enemies_killed", 0)))
	lines.append("LevelUp Active: %s" % str(data.get("is_level_up_active", false)))
	lines.append("Pending LevelUps: %s" % str(data.get("pending_level_ups", 0)))

func _append_run_economy_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN ECONOMY")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Run Coins: %s" % str(data.get("run_coins_collected", 0)))
	lines.append("Coins Available: %s" % str(data.get("run_coins_available", 0)))
	lines.append("Coins Spent: %s" % str(data.get("run_coins_spent", 0)))

func _append_run_result_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN RESULT")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Finished: %s" % str(data.get("is_finished", false)))
	lines.append("Victory: %s" % str(data.get("is_victory", false)))
	lines.append("Defeat: %s" % str(data.get("is_defeat", false)))
	lines.append("Result: %s" % str(data.get("result_type", "")))
	lines.append("Final Money: %s" % str(data.get("final_money_reward", 0)))
	lines.append("Death Cause: %s" % str(data.get("death_cause", "")))

func _append_save_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("SAVE")

	if data.is_empty() or not bool(data.get("has_save_data", false)):
		lines.append("Save: não encontrado")
		return

	lines.append("Total XP: %s" % str(data.get("total_xp", 0)))
	lines.append("Total Money: %s" % str(data.get("total_money", 0)))
	lines.append("Completed Maps: %s" % _format_limited_array(data.get("completed_maps", []), max_completed_maps_to_show))
	lines.append("SFW: %s" % str(data.get("sfw_enabled", true)))

func _append_technical_section(lines: Array[String], player_data: Dictionary, run_data: Dictionary, save_data: Dictionary) -> void:
	lines.append("TECHNICAL")
	lines.append("Has Player Data: %s" % str(not player_data.is_empty()))
	lines.append("Has Run Data: %s" % str(not run_data.is_empty()))
	lines.append("Has Save Data: %s" % str(bool(save_data.get("has_save_data", false))))
	lines.append("Paused Tree: %s" % str(get_tree().paused))
	lines.append("Panel Size: %s" % _format_vector(panel_size))

func _append_separator(lines: Array[String]) -> void:
	if not show_separators:
		return

	if lines.is_empty():
		return

	lines.append("--------------------")

func _configure_panel() -> void:
	if panel != null:
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.position = panel_position
		panel.size = panel_size
		panel.custom_minimum_size = panel_size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin_container: MarginContainer = get_node_or_null("Panel/MarginContainer") as MarginContainer

	if margin_container != null:
		margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin_container.offset_left = panel_margin
		margin_container.offset_top = panel_margin
		margin_container.offset_right = -panel_margin
		margin_container.offset_bottom = -panel_margin
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

func _get_debug_data_from_node(node: Node) -> Dictionary:
	if node == null:
		return {}

	if not node.has_method("get_debug_data"):
		return {}

	var debug_data_variant: Variant = node.call("get_debug_data")

	if debug_data_variant is Dictionary:
		return debug_data_variant as Dictionary

	return {}

func _format_vector(value: Variant) -> String:
	if not value is Vector2:
		return str(value)

	var vector: Vector2 = value as Vector2

	if compact_vectors:
		return "(%s, %s)" % [
			_format_float(vector.x),
			_format_float(vector.y)
		]

	return str(vector)

func _format_float(value: float) -> String:
	var safe_decimal_places: int = max(0, decimal_places)
	var format_string: String = "%." + str(safe_decimal_places) + "f"

	return format_string % value

func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(max(0.0, seconds)))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]

func _format_limited_array(value: Variant, limit: int) -> String:
	if not value is Array:
		return str(value)

	var array_value: Array = value as Array

	if array_value.size() <= limit:
		return str(array_value)

	var visible_items: Array = []

	for index: int in range(limit):
		visible_items.append(array_value[index])

	return "%s +%s" % [
		str(visible_items),
		str(array_value.size() - limit)
	]

func _on_spine_animation_changed(animation_name: String) -> void:
	last_animation_name = animation_name
