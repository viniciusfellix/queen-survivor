extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var result_type_label: Label = $Panel/MarginContainer/VBoxContainer/ResultTypeLabel
@onready var summary_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryLabel
@onready var save_status_label: Label = $Panel/MarginContainer/VBoxContainer/SaveStatusLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/RestartButton

var latest_result_payload: RunResultPayload = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if restart_button != null:
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

		if not restart_button.pressed.is_connected(_on_restart_button_pressed):
			restart_button.pressed.connect(_on_restart_button_pressed)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

	if not GameEvents.save_updated.is_connected(_on_save_updated):
		GameEvents.save_updated.connect(_on_save_updated)

func _on_run_finished(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	latest_result_payload = result_payload

	visible = true

	title_label.text = LocalizationManager.get_text("ui.result.title")

	if result_payload.victory:
		result_type_label.text = LocalizationManager.get_text("ui.result.victory")
	else:
		result_type_label.text = LocalizationManager.get_text("ui.result.defeat")

	summary_label.text = _build_summary_text(result_payload)

	if save_status_label != null:
		save_status_label.text = "Salvando resultado..."

	hint_label.text = LocalizationManager.get_text("ui.result.close_hint")

	if restart_button != null:
		restart_button.text = LocalizationManager.get_text("ui.result.restart")
		restart_button.disabled = false

	GameEvents.emit_debug("[ResultPanel] Resultado exibido: %s" % result_payload.result_type)

func _on_save_updated(_save_data: SaveData) -> void:
	if not visible:
		return

	if save_status_label != null:
		save_status_label.text = LocalizationManager.get_text("ui.result.save_applied")

func _on_restart_button_pressed() -> void:
	GameEvents.emit_debug("[ResultPanel] Reinício solicitado pelo jogador.")

	GameEvents.run_restart_requested.emit()

	get_tree().paused = false
	get_tree().reload_current_scene()

func _build_summary_text(payload: RunResultPayload) -> String:
	var lines: Array[String] = []

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.map"),
		payload.map_id
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.queen"),
		payload.queen_id
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.time_survived"),
		_format_seconds(payload.survived_seconds)
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.coins_collected"),
		str(payload.run_coins_collected)
	])

	if payload.victory:
		lines.append("Multiplicador: x%s" % str(payload.victory_multiplier))
		lines.append("Bônus: %s" % str(payload.victory_bonus))

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.final_money"),
		str(payload.final_money_reward)
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.xp_gained"),
		str(payload.run_xp_gained)
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.enemies_killed"),
		str(payload.enemies_killed)
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.level_reached"),
		str(payload.level_reached)
	])

	lines.append("Dano causado: %s" % str(payload.damage_dealt))
	lines.append("Dano recebido: %s" % str(payload.damage_taken))

	if payload.defeat:
		lines.append("%s: %s" % [
			LocalizationManager.get_text("ui.result.death_cause"),
			payload.death_cause
		])

	return "\n".join(lines)

func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(seconds))
	var minutes: int = total_seconds / 60
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]
