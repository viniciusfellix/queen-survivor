## Painel final exibido após vitória ou derrota.
##
## Responsabilidades:
## - apresentar o resultado final da run;
## - montar o resumo de desempenho;
## - indicar se o resultado foi persistido no save;
## - permitir reiniciar a cena para uma nova tentativa.
##
## O painel separa dois momentos:
## - `run_finished`: gameplay encerrou e o resultado pode ser exibido;
## - `run_result_persisted`: o `SaveManager` informou se salvou com sucesso.
extends CanvasLayer

## Referências aos elementos fixos da tela de resultado.
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var result_type_label: Label = $Panel/MarginContainer/VBoxContainer/ResultTypeLabel
@onready var summary_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryLabel
@onready var save_status_label: Label = $Panel/MarginContainer/VBoxContainer/SaveStatusLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/RestartButton

## Último resultado recebido para exibição.
var latest_result_payload: RunResultPayload = null

## Resultado que já recebeu confirmação de persistência do save.
var persisted_result_payload: RunResultPayload = null

## Resultado da última tentativa de salvar a run finalizada.
var persisted_result_succeeded: bool = false

## Inicializa o painel oculto e conecta os events de resultado e persistência.
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

## Exibe o resultado final publicado pelo `RunController`.
##
## Neste momento, o resultado já está definido, mas o status de save
## pode ainda estar aguardando confirmação do `SaveManager`.
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

	_update_save_status_label()

	hint_label.text = LocalizationManager.get_text("ui.result.close_hint")

	if restart_button != null:
		restart_button.text = LocalizationManager.get_text("ui.result.restart")
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

## Recebe confirmação de que o resultado foi processado pelo save.
##
## Atualiza o status visual somente quando a confirmação pertence
## ao mesmo payload que está sendo mostrado atualmente.
func _on_run_result_persisted(
	result_payload: RunResultPayload,
	_save_data: SaveData,
	succeeded: bool
) -> void:
	persisted_result_payload = result_payload
	persisted_result_succeeded = succeeded

	if latest_result_payload == result_payload:
		_update_save_status_label()

## Atualiza o texto que informa a situação do salvamento.
##
## Estados possíveis:
## - sem resultado exibido;
## - aguardando persistência;
## - persistência concluída;
## - falha ao salvar.
func _update_save_status_label() -> void:
	if save_status_label == null:
		return

	if latest_result_payload == null:
		save_status_label.text = ""
		return

	if persisted_result_payload != latest_result_payload:
		save_status_label.text = LocalizationManager.get_text("ui.result.saving")
		return

	if persisted_result_succeeded:
		save_status_label.text = LocalizationManager.get_text("ui.result.save_applied")
	else:
		save_status_label.text = LocalizationManager.get_text("ui.result.save_failed")

## Reinicia a cena atual após solicitação do jogador.
##
## Remove a pausa da árvore antes do reload para evitar
## iniciar a próxima tentativa em estado bloqueado.
func _on_restart_button_pressed() -> void:
	DeveloperAuditLogger.log_ui(
		"Reinício solicitado pelo jogador.",
		"ResultPanel"
	)

	get_tree().paused = false
	get_tree().reload_current_scene()

## Monta o resumo textual exibido no painel.
##
## Em vitória, inclui multiplicador e bônus do mapa.
## Em derrota, inclui a causa registrada da morte.
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
		lines.append("%s: x%s" % [
			LocalizationManager.get_text("ui.result.victory_multiplier"),
			str(payload.victory_multiplier)
		])

		lines.append("%s: %s" % [
			LocalizationManager.get_text("ui.result.victory_bonus"),
			str(payload.victory_bonus)
		])

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

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.damage_dealt"),
		str(payload.damage_dealt)
	])

	lines.append("%s: %s" % [
		LocalizationManager.get_text("ui.result.damage_taken"),
		str(payload.damage_taken)
	])

	if payload.defeat:
		lines.append("%s: %s" % [
			LocalizationManager.get_text("ui.result.death_cause"),
			payload.death_cause
		])

	return "\n".join(lines)

## Converte tempo em segundos para o formato textual `MM:SS`.
func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(seconds))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]
