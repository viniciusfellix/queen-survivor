## Painel de resultado final da run.
##
## Responsabilidades:
## - exibir vitória ou derrota;
## - mostrar resumo da run;
## - informar se o save foi persistido com sucesso;
## - permitir reiniciar a cena atual;
## - reagir aos eventos globais de fim da run e persistência.
##
## Importante:
## Este painel não calcula recompensa.
## Ele apenas exibe dados já calculados em RunResultPayload.
extends CanvasLayer

## Referências dos nodes principais.
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var result_type_label: Label = $Panel/MarginContainer/VBoxContainer/ResultTypeLabel
@onready var summary_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryLabel
@onready var save_status_label: Label = $Panel/MarginContainer/VBoxContainer/SaveStatusLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/RestartButton

## Resultado mais recente recebido.
var latest_result_payload: RunResultPayload = null

## Payload que já teve tentativa de persistência confirmada.
var persisted_result_payload: RunResultPayload = null

## Resultado da tentativa de persistência do save.
var persisted_result_succeeded: bool = false

## Inicializa painel oculto e conecta eventos.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if restart_button != null:
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

		if not restart_button.pressed.is_connected(_on_restart_button_pressed):
			restart_button.pressed.connect(_on_restart_button_pressed)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

	if not GameEvents.run_result_persisted.is_connected(_on_run_result_persisted):
		GameEvents.run_result_persisted.connect(_on_run_result_persisted)

## Abre painel quando a run termina.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	latest_result_payload = result_payload

	visible = true

	title_label.text = tr("ui.result.title")

	if result_payload.victory:
		result_type_label.text = tr("ui.result.victory")
	else:
		result_type_label.text = tr("ui.result.defeat")

	summary_label.text = _build_summary_text(result_payload)

	_update_save_status_label()

	hint_label.text = tr("ui.result.close_hint")

	if restart_button != null:
		restart_button.text = tr("ui.result.restart")
		restart_button.disabled = false

	DeveloperAuditLogger.log_ui(
		"Resultado exibido: %s" % result_payload.result_type,
		"ResultPanel",
		{
			"result_type": result_payload.result_type,
			"victory": result_payload.victory,
			"defeat": result_payload.defeat
		}
	)

## Recebe confirmação de persistência do resultado no save.
func _on_run_result_persisted(
	result_payload: RunResultPayload,
	_save_data: SaveData,
	succeeded: bool
) -> void:
	persisted_result_payload = result_payload
	persisted_result_succeeded = succeeded

	if latest_result_payload == result_payload:
		_update_save_status_label()

## Atualiza texto de status do save.
func _update_save_status_label() -> void:
	if save_status_label == null:
		return

	if latest_result_payload == null:
		save_status_label.text = ""
		return

	if persisted_result_payload != latest_result_payload:
		save_status_label.text = tr("ui.result.saving")
		return

	if persisted_result_succeeded:
		save_status_label.text = tr("ui.result.save_applied")
	else:
		save_status_label.text = tr("ui.result.save_failed")

## Reinicia a cena atual.
func _on_restart_button_pressed() -> void:
	DeveloperAuditLogger.log_ui(
		"Reinício solicitado pelo jogador.",
		"ResultPanel"
	)

	get_tree().paused = false
	get_tree().reload_current_scene()

## Monta resumo textual da run.
func _build_summary_text(payload: RunResultPayload) -> String:
	var lines: Array[String] = []

	lines.append("%s: %s" % [
		tr("ui.result.map"),
		payload.map_id
	])

	lines.append("%s: %s" % [
		tr("ui.result.queen"),
		payload.queen_id
	])

	lines.append("%s: %s" % [
		tr("ui.result.time_survived"),
		_format_seconds(payload.survived_seconds)
	])

	lines.append("%s: %s" % [
		tr("ui.result.coins_collected"),
		str(payload.run_coins_collected)
	])

	if payload.victory:
		lines.append("%s: x%s" % [
			tr("ui.result.victory_multiplier"),
			str(payload.victory_multiplier)
		])

		lines.append("%s: %s" % [
			tr("ui.result.victory_bonus"),
			str(payload.victory_bonus)
		])

	lines.append("%s: %s" % [
		tr("ui.result.final_money"),
		str(payload.final_money_reward)
	])

	lines.append("%s: %s" % [
		tr("ui.result.xp_gained"),
		str(payload.run_xp_gained)
	])

	lines.append("%s: %s" % [
		tr("ui.result.enemies_killed"),
		str(payload.enemies_killed)
	])

	lines.append("%s: %s" % [
		tr("ui.result.level_reached"),
		str(payload.level_reached)
	])

	lines.append("%s: %s" % [
		tr("ui.result.damage_dealt"),
		str(payload.damage_dealt)
	])

	lines.append("%s: %s" % [
		tr("ui.result.damage_taken"),
		str(payload.damage_taken)
	])

	if payload.defeat:
		lines.append("%s: %s" % [
			tr("ui.result.death_cause"),
			payload.death_cause
		])

	return "\n".join(lines)

## Formata segundos como MM:SS.
func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(seconds))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]
