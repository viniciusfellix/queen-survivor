extends CanvasLayer

@export var metrics_enabled: bool = true
@export var toggle_with_f6: bool = true
@export var update_interval_seconds: float = 0.25

@export_group("Layout")
@export var panel_position: Vector2 = Vector2(16.0, 16.0)
@export var panel_size: Vector2 = Vector2(430.0, 320.0)

@export_group("Scene References")
@export var enemy_spawner_path: NodePath
@export var drop_controller_path: NodePath
@export var run_controller_path: NodePath

@onready var panel: Panel = get_node_or_null("Panel") as Panel
@onready var label: Label = get_node_or_null("Panel/MarginContainer/Label") as Label

var _refresh_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if panel != null:
		panel.position = panel_position
		panel.size = panel_size
		panel.custom_minimum_size = panel_size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_update_visibility()
	_refresh_text()


func _process(delta: float) -> void:
	_update_visibility()

	if not metrics_enabled:
		return

	_refresh_timer += delta

	if _refresh_timer < max(0.05, update_interval_seconds):
		return

	_refresh_timer = 0.0
	_refresh_text()


func _unhandled_input(event: InputEvent) -> void:
	if not toggle_with_f6:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode != KEY_F6:
		return

	metrics_enabled = not metrics_enabled
	_update_visibility()

	if metrics_enabled:
		_refresh_text()

	get_viewport().set_input_as_handled()


func _update_visibility() -> void:
	if panel != null:
		panel.visible = metrics_enabled


func _refresh_text() -> void:
	if label == null:
		return

	var enemy_spawner_data: Dictionary = _get_debug_data_from_path(enemy_spawner_path)
	var drop_controller_data: Dictionary = _get_debug_data_from_path(drop_controller_path)
	var run_controller_data: Dictionary = _get_debug_data_from_path(run_controller_path)
	var pool_data: Dictionary = PoolManager.get_debug_data()

	var fps: int = Engine.get_frames_per_second()
	var process_time: Variant = _get_performance_monitor(Performance.TIME_PROCESS)
	var physics_time: Variant = _get_performance_monitor(Performance.TIME_PHYSICS_PROCESS)
	var node_count: Variant = _get_performance_monitor(Performance.OBJECT_NODE_COUNT)
	var object_count: Variant = _get_performance_monitor(Performance.OBJECT_COUNT)

	var lines: Array[String] = [
		"STRESS METRICS",
		"Status: %s" % _get_status_label(fps),
		"",
		"FPS: %s" % str(fps),
		"Process: %s" % _format_monitor_value(process_time),
		"Physics: %s" % _format_monitor_value(physics_time),
		"Nodes: %s" % _format_monitor_value(node_count, 0),
		"Objects: %s" % _format_monitor_value(object_count, 0),
		"",
		"Run Time: %s" % _format_seconds(float(run_controller_data.get("elapsed_seconds", 0.0))),
		"Enemies Alive: %s" % str(enemy_spawner_data.get("alive_enemy_count", "n/a")),
		"Total Spawned: %s" % str(enemy_spawner_data.get("total_spawned", "n/a")),
		"Active Waves: %s" % str(enemy_spawner_data.get("active_wave_count", "n/a")),
		"Active Rules: %s" % str(enemy_spawner_data.get("active_rule_count", "n/a")),
		"Global Max Alive: %s" % str(enemy_spawner_data.get("effective_global_max_alive", "n/a")),
		"Drops Alive: %s" % str(drop_controller_data.get("alive_drop_count", "n/a")),
		"Pool Free Total: %s" % str(pool_data.get("total_free_nodes", "n/a")),
		"Pool Scenes: %s" % str(pool_data.get("pooled_scene_count", "n/a")),
		"",
		"Wave IDs: %s" % _format_string_array(enemy_spawner_data.get("active_wave_ids", [])),
		"Rule Keys: %s" % _format_string_array(enemy_spawner_data.get("active_rule_keys", [])),
		"Pool Summary: %s" % _format_pool_summary(pool_data.get("free_count_by_key", {})),
		"",
		"F6: toggle overlay"
	]

	label.text = "\n".join(lines)


func _get_debug_data_from_path(node_path: NodePath) -> Dictionary:
	if node_path == NodePath():
		return {}

	var node: Node = get_node_or_null(node_path)

	if node == null:
		return {}

	if not node.has_method("get_debug_data"):
		return {}

	var data_variant: Variant = node.call("get_debug_data")

	if data_variant is Dictionary:
		return data_variant

	return {}


func _get_performance_monitor(monitor: int) -> Variant:
	return Performance.get_monitor(monitor)


func _format_monitor_value(value: Variant, decimals: int = 2) -> String:
	if value == null:
		return "n/a"

	if value is float:
		return ("%." + str(max(0, decimals)) + "f") % float(value)

	if value is int:
		return str(value)

	return "n/a"


func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(max(0.0, seconds)))
	var minutes: int = int(total_seconds / 60)
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]


func _format_string_array(value: Variant) -> String:
	if not value is Array:
		return "n/a"

	var items: Array = value

	if items.is_empty():
		return "-"

	var parts: Array[String] = []

	for item: Variant in items:
		parts.append(str(item))

	return ", ".join(parts)


func _format_pool_summary(value: Variant) -> String:
	if not value is Dictionary:
		return "n/a"

	var summary: Dictionary = value

	if summary.is_empty():
		return "-"

	var keys: Array = summary.keys()
	keys.sort()

	var parts: Array[String] = []

	for key_variant: Variant in keys:
		var key: String = str(key_variant)
		var short_key: String = key.get_file()
		parts.append("%s=%s" % [short_key, str(summary.get(key_variant, 0))])

	return ", ".join(parts)


func _get_status_label(fps: int) -> String:
	if fps >= 50:
		return "OK"

	if fps >= 30:
		return "WARNING"

	return "CRITICAL"
