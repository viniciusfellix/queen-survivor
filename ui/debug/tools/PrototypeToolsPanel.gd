extends CanvasLayer

const TOGGLE_KEY: Key = KEY_F3

@export_group("Availability")
@export var tools_enabled: bool = true
@export var visible_on_start: bool = false
@export var allow_save_reset: bool = true
@export var allow_force_result_actions: bool = true

@export_group("Layout")
@export var panel_size: Vector2 = Vector2(680.0, 520.0)
@export var panel_margin: float = 16.0

@export_group("Refresh")
@export var refresh_interval_seconds: float = 0.20

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel

@onready var save_info_label: Label = $Panel/MarginContainer/VBoxContainer/SaveInfoLabel
@onready var current_run_label: Label = $Panel/MarginContainer/VBoxContainer/CurrentRunLabel
@onready var last_run_label: Label = $Panel/MarginContainer/VBoxContainer/LastRunLabel

@onready var warning_label: Label = $Panel/MarginContainer/VBoxContainer/WarningLabel
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel

@onready var force_victory_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsRow/ForceVictoryButton
@onready var force_defeat_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsRow/ForceDefeatButton
@onready var reset_progress_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsRow/ResetProgressButton

@onready var confirmation_row: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ConfirmationRow
@onready var confirm_reset_button: Button = $Panel/MarginContainer/VBoxContainer/ConfirmationRow/ConfirmResetButton
@onready var cancel_reset_button: Button = $Panel/MarginContainer/VBoxContainer/ConfirmationRow/CancelResetButton

var refresh_timer: float = 0.0
var reset_confirmation_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	visible = tools_enabled and visible_on_start

	_configure_layout()
	_configure_static_texts()
	_connect_buttons()
	_connect_events()
	_set_reset_confirmation_visible(false)
	_refresh_panel()

	GameEvents.emit_debug("[PrototypeToolsPanel] Inicializado. Pressione F3 para mostrar/ocultar.")

func _process(delta: float) -> void:
	if not tools_enabled:
		visible = false
		return

	if not visible:
		return

	refresh_timer += delta

	if refresh_timer < refresh_interval_seconds:
		return

	refresh_timer = 0.0
	_refresh_panel()

func _unhandled_input(event: InputEvent) -> void:
	if not tools_enabled:
		return

	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if key_event.keycode != TOGGLE_KEY:
		return

	visible = not visible

	if visible:
		_refresh_panel()

	get_viewport().set_input_as_handled()

func _configure_layout() -> void:
	if panel == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var safe_panel_size: Vector2 = Vector2(
		min(panel_size.x, viewport_size.x - (panel_margin * 2.0)),
		min(panel_size.y, viewport_size.y - (panel_margin * 2.0))
	)

	panel.size = safe_panel_size
	panel.custom_minimum_size = safe_panel_size
	panel.position = Vector2(
		max(panel_margin, viewport_size.x - safe_panel_size.x - panel_margin),
		panel_margin
	)

	var margin_container: MarginContainer = panel.get_node_or_null("MarginContainer") as MarginContainer

	if margin_container == null:
		return

	margin_container.position = Vector2.ZERO
	margin_container.size = safe_panel_size
	margin_container.custom_minimum_size = safe_panel_size

	margin_container.add_theme_constant_override("margin_left", 16)
	margin_container.add_theme_constant_override("margin_top", 16)
	margin_container.add_theme_constant_override("margin_right", 16)
	margin_container.add_theme_constant_override("margin_bottom", 16)

func _configure_static_texts() -> void:
	title_label.text = LocalizationManager.get_text("ui.debug_tools.title")
	hint_label.text = LocalizationManager.get_text("ui.debug_tools.toggle_hint")

	force_victory_button.text = LocalizationManager.get_text("ui.debug_tools.force_victory")
	force_defeat_button.text = LocalizationManager.get_text("ui.debug_tools.force_defeat")
	reset_progress_button.text = LocalizationManager.get_text("ui.debug_tools.reset_progression")

	confirm_reset_button.text = LocalizationManager.get_text("ui.debug_tools.confirm_reset")
	cancel_reset_button.text = LocalizationManager.get_text("ui.debug_tools.cancel")

	warning_label.text = LocalizationManager.get_text("ui.debug_tools.force_result_warning")
	status_label.text = ""

	force_victory_button.disabled = not allow_force_result_actions
	force_defeat_button.disabled = not allow_force_result_actions
	reset_progress_button.disabled = not allow_save_reset

func _connect_buttons() -> void:
	if not force_victory_button.pressed.is_connected(_on_force_victory_pressed):
		force_victory_button.pressed.connect(_on_force_victory_pressed)

	if not force_defeat_button.pressed.is_connected(_on_force_defeat_pressed):
		force_defeat_button.pressed.connect(_on_force_defeat_pressed)

	if not reset_progress_button.pressed.is_connected(_on_reset_progress_pressed):
		reset_progress_button.pressed.connect(_on_reset_progress_pressed)

	if not confirm_reset_button.pressed.is_connected(_on_confirm_reset_pressed):
		confirm_reset_button.pressed.connect(_on_confirm_reset_pressed)

	if not cancel_reset_button.pressed.is_connected(_on_cancel_reset_pressed):
		cancel_reset_button.pressed.connect(_on_cancel_reset_pressed)

func _connect_events() -> void:
	if not GameEvents.save_updated.is_connected(_on_save_updated):
		GameEvents.save_updated.connect(_on_save_updated)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

func _refresh_panel() -> void:
	_configure_layout()
	_refresh_save_info()
	_refresh_current_run_info()
	_refresh_last_run_info()

func _refresh_save_info() -> void:
	var save_debug: Dictionary = SaveManager.get_debug_data()

	if not bool(save_debug.get("has_save_data", false)):
		save_info_label.text = "Save: -"
		return

	var completed_maps: Array = save_debug.get("completed_maps", []) as Array

	save_info_label.text = "%s: %s\n%s: %s\n%s: %s" % [
		LocalizationManager.get_text("ui.debug_tools.total_xp"),
		str(save_debug.get("total_xp", 0)),
		LocalizationManager.get_text("ui.debug_tools.total_money"),
		str(save_debug.get("total_money", 0)),
		LocalizationManager.get_text("ui.debug_tools.completed_maps"),
		_format_completed_maps(completed_maps)
	]

func _refresh_current_run_info() -> void:
	var run_controller: Node = _get_run_controller()

	if run_controller == null or not run_controller.has_method("get_debug_data"):
		current_run_label.text = "%s: -" % LocalizationManager.get_text("ui.debug_tools.current_run")
		return

	var run_data_variant: Variant = run_controller.call("get_debug_data")

	if not run_data_variant is Dictionary:
		current_run_label.text = "%s: -" % LocalizationManager.get_text("ui.debug_tools.current_run")
		return

	var run_data: Dictionary = run_data_variant as Dictionary
	var is_finished: bool = bool(run_data.get("is_finished", false))

	var run_status: String = LocalizationManager.get_text("ui.debug_tools.finished") if is_finished else LocalizationManager.get_text("ui.debug_tools.active")

	current_run_label.text = "%s: %s | XP: %s | Coins: %s | Level: %s" % [
		LocalizationManager.get_text("ui.debug_tools.current_run"),
		run_status,
		str(run_data.get("run_xp_gained", 0)),
		str(run_data.get("run_coins_collected", 0)),
		str(run_data.get("current_level", 1))
	]

func _refresh_last_run_info() -> void:
	var save_debug: Dictionary = SaveManager.get_debug_data()
	var last_run_variant: Variant = save_debug.get("last_run_summary", {})

	if not last_run_variant is Dictionary:
		last_run_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.debug_tools.last_run"),
			LocalizationManager.get_text("ui.debug_tools.no_last_run")
		]
		return

	var last_run: Dictionary = last_run_variant as Dictionary

	if last_run.is_empty():
		last_run_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.debug_tools.last_run"),
			LocalizationManager.get_text("ui.debug_tools.no_last_run")
		]
		return

	last_run_label.text = "%s: %s | XP: %s | Money: %s | Kills: %s" % [
		LocalizationManager.get_text("ui.debug_tools.last_run"),
		str(last_run.get("result_type", "-")),
		str(last_run.get("run_xp_gained", 0)),
		str(last_run.get("final_money_reward", 0)),
		str(last_run.get("enemies_killed", 0))
	]

func _on_force_victory_pressed() -> void:
	if not allow_force_result_actions:
		return

	var run_controller: Node = _get_run_controller()

	if run_controller == null or not run_controller.has_method("debug_force_victory"):
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_disabled")
		return

	var result_variant: Variant = run_controller.call("debug_force_victory")
	var succeeded: bool = bool(result_variant)

	if succeeded:
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_victory_done")
	else:
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_disabled")

	_refresh_panel()

func _on_force_defeat_pressed() -> void:
	if not allow_force_result_actions:
		return

	var run_controller: Node = _get_run_controller()

	if run_controller == null or not run_controller.has_method("debug_force_defeat"):
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_disabled")
		return

	var result_variant: Variant = run_controller.call("debug_force_defeat")
	var succeeded: bool = bool(result_variant)

	if succeeded:
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_defeat_done")
	else:
		status_label.text = LocalizationManager.get_text("ui.debug_tools.force_disabled")

	_refresh_panel()

func _on_reset_progress_pressed() -> void:
	if not allow_save_reset:
		return

	reset_confirmation_active = true
	status_label.text = LocalizationManager.get_text("ui.debug_tools.reset_warning")
	_set_reset_confirmation_visible(true)

func _on_confirm_reset_pressed() -> void:
	if not reset_confirmation_active:
		return

	SaveManager.reset_progression_and_save()

	reset_confirmation_active = false
	_set_reset_confirmation_visible(false)

	status_label.text = LocalizationManager.get_text("ui.debug_tools.reset_done")
	_refresh_panel()

func _on_cancel_reset_pressed() -> void:
	reset_confirmation_active = false
	_set_reset_confirmation_visible(false)

	status_label.text = LocalizationManager.get_text("ui.debug_tools.reset_cancelled")

func _set_reset_confirmation_visible(should_show: bool) -> void:
	if confirmation_row == null:
		push_warning("[PrototypeToolsPanel] ConfirmationRow não encontrado.")
		return

	confirmation_row.visible = should_show
	reset_progress_button.disabled = should_show or not allow_save_reset

	GameEvents.emit_debug("[PrototypeToolsPanel] ConfirmationRow visible=%s position=%s size=%s" % [
		str(confirmation_row.visible),
		str(confirmation_row.position),
		str(confirmation_row.size)
	])

func _on_save_updated(_save_data: SaveData) -> void:
	_refresh_panel()

func _on_run_finished(_result_payload: RunResultPayload) -> void:
	_refresh_panel()

func _get_run_controller() -> Node:
	var run_controllers: Array[Node] = get_tree().get_nodes_in_group("run_controller")

	if run_controllers.is_empty():
		return null

	return run_controllers[0]

func _format_completed_maps(completed_maps: Array) -> String:
	if completed_maps.is_empty():
		return LocalizationManager.get_text("ui.debug_tools.none")

	var map_names: Array[String] = []

	for map_id_variant: Variant in completed_maps:
		map_names.append(str(map_id_variant))

	return ", ".join(map_names)
