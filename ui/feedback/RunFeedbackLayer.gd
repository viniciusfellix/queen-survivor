## Camada de feedback textual simples da run.
##
## Responsabilidades:
## - exibir mensagens temporárias na tela;
## - reagir a eventos globais da run;
## - mostrar feedback textual de moeda, level-up, dano e resultado;
## - limitar a quantidade de mensagens simultâneas.
##
## Observação:
## Este feedback é textual e geral.
## O dano flutuante no mundo é tratado por WorldFeedbackLayer/FloatingCombatText.
extends CanvasLayer

## Tempo de vida de cada mensagem exibida.
@export var message_lifetime_seconds: float = 1.2

## Quantidade máxima de mensagens simultâneas.
@export var max_messages: int = 5

## Define se dano recebido deve aparecer nesta camada textual.
##
## Atualmente pode ficar false para evitar duplicar o floating damage.
@export var show_damage_feedback: bool = false

## Define se coleta de moeda deve gerar mensagem textual.
@export var show_coin_feedback: bool = true

## Define se level-up deve gerar mensagem textual.
@export var show_level_up_feedback: bool = true

## Define se vitória/derrota deve gerar mensagem textual.
@export var show_result_feedback: bool = false

## Container vertical onde as mensagens são adicionadas.
@onready var message_container: VBoxContainer = $MarginContainer/MessageContainer

## Lista de labels atualmente ativos.
var active_messages: Array[Label] = []

## Inicializa a camada, conecta eventos e registra configuração.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_events()

	DeveloperAuditLogger.log_ui(
		"Feedback textual inicializado.",
		"RunFeedbackLayer",
		{
			"show_damage_feedback": show_damage_feedback,
			"show_coin_feedback": show_coin_feedback,
			"show_level_up_feedback": show_level_up_feedback,
			"show_result_feedback": show_result_feedback
		}
	)

## Conecta esta camada aos eventos globais relevantes.
func _connect_events() -> void:
	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	if not GameEvents.run_coin_collected.is_connected(_on_run_coin_collected):
		GameEvents.run_coin_collected.connect(_on_run_coin_collected)

	if not GameEvents.run_level_up_started.is_connected(_on_run_level_up_started):
		GameEvents.run_level_up_started.connect(_on_run_level_up_started)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Exibe uma mensagem temporária na tela.
##
## A mensagem é removida automaticamente após `message_lifetime_seconds`.
func show_feedback(message: String) -> void:
	if message.strip_edges() == "":
		return

	if message_container == null:
		return

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	message_container.add_child(label)
	active_messages.append(label)

	## Remove mensagens mais antigas quando ultrapassa o limite.
	while active_messages.size() > max_messages:
		var old_label: Label = active_messages.pop_front()

		if old_label != null and is_instance_valid(old_label):
			old_label.queue_free()

	var timer: SceneTreeTimer = get_tree().create_timer(message_lifetime_seconds)

	timer.timeout.connect(func() -> void:
		_remove_message(label)
	)

## Remove uma mensagem específica da lista e da árvore.
func _remove_message(label: Label) -> void:
	if label == null:
		return

	if active_messages.has(label):
		active_messages.erase(label)

	if is_instance_valid(label):
		label.queue_free()

## Evento de dano recebido pelo player.
func _on_player_damaged(
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if not show_damage_feedback:
		return

	show_feedback("%s: -%s" % [
		tr("ui.feedback.damage_taken"),
		str(final_damage)
	])

## Evento de moeda coletada.
func _on_run_coin_collected(value: int, _global_position: Vector2) -> void:
	if not show_coin_feedback:
		return

	show_feedback("%s: +%s" % [
		tr("ui.feedback.coin_collected"),
		str(value)
	])

## Evento de início de level-up.
func _on_run_level_up_started(current_level: int, _options: Array) -> void:
	if not show_level_up_feedback:
		return

	show_feedback("%s %s" % [
		tr("ui.feedback.level_up"),
		str(current_level)
	])

## Evento de fim da run.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	if not show_result_feedback:
		return

	if result_payload == null:
		return

	if result_payload.victory:
		show_feedback(tr("ui.feedback.victory"))
	else:
		show_feedback(tr("ui.feedback.defeat"))
