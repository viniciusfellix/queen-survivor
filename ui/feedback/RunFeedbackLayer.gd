## Camada de mensagens textuais rápidas exibidas durante a run.
##
## Responsabilidades:
## - mostrar confirmação breve de coleta de moeda;
## - informar level-up quando uma escolha é iniciada;
## - oferecer suporte opcional para mensagens de dano e resultado.
##
## No estado atual do protótipo:
## - dano é apresentado principalmente por `FloatingCombatText`;
## - vitória e derrota são apresentadas principalmente por `ResultPanel`;
## portanto esses dois feedbacks permanecem desativados por padrão.
extends CanvasLayer

## Tempo, em segundos, que cada mensagem permanece na tela.
@export var message_lifetime_seconds: float = 1.2

## Quantidade máxima de mensagens simultâneas visíveis.
@export var max_messages: int = 5

## Define se esta camada também mostra dano recebido.
##
## Dano já possui feedback flutuante sobre a Gaia;
## manter esta opção desativada evita informação duplicada.
@export var show_damage_feedback: bool = false

## Define se a coleta de moeda gera mensagem textual.
@export var show_coin_feedback: bool = true

## Define se o início de um level-up gera mensagem textual.
@export var show_level_up_feedback: bool = true

## Define se vitória ou derrota geram mensagem nesta camada.
##
## O painel de resultado já cobre esse momento no fluxo atual.
@export var show_result_feedback: bool = false

## Container vertical onde labels temporários são adicionados.
@onready var message_container: VBoxContainer = $MarginContainer/MessageContainer

## Lista das mensagens que ainda estão ativas na tela.
var active_messages: Array[Label] = []

## Inicializa a camada e conecta os events utilizados pelos feedbacks.
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

## Conecta events de gameplay aos métodos de feedback correspondentes.
func _connect_events() -> void:
	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	if not GameEvents.run_coin_collected.is_connected(_on_run_coin_collected):
		GameEvents.run_coin_collected.connect(_on_run_coin_collected)

	if not GameEvents.run_level_up_started.is_connected(_on_run_level_up_started):
		GameEvents.run_level_up_started.connect(_on_run_level_up_started)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Cria uma mensagem textual temporária na camada de feedback.
##
## Quando o limite máximo é excedido, remove primeiro
## a mensagem mais antiga ainda ativa.
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

	while active_messages.size() > max_messages:
		var old_label: Label = active_messages.pop_front()

		if old_label != null and is_instance_valid(old_label):
			old_label.queue_free()

	var timer: SceneTreeTimer = get_tree().create_timer(message_lifetime_seconds)

	timer.timeout.connect(func() -> void:
		_remove_message(label)
	)

## Remove uma mensagem da lista ativa e da árvore visual.
func _remove_message(label: Label) -> void:
	if label == null:
		return

	if active_messages.has(label):
		active_messages.erase(label)

	if is_instance_valid(label):
		label.queue_free()

## Exibe dano textual quando essa opção estiver habilitada.
##
## No layout atual permanece desativado para evitar duplicação
## com o texto flutuante exibido junto à personagem.
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
		LocalizationManager.get_text("ui.feedback.damage_taken"),
		str(final_damage)
	])

## Exibe confirmação breve quando uma moeda física é coletada.
func _on_run_coin_collected(value: int, _global_position: Vector2) -> void:
	if not show_coin_feedback:
		return

	show_feedback("%s: +%s" % [
		LocalizationManager.get_text("ui.feedback.coin_collected"),
		str(value)
	])

## Exibe mensagem breve quando uma nova escolha de upgrade começa.
func _on_run_level_up_started(current_level: int, _options: Array) -> void:
	if not show_level_up_feedback:
		return

	show_feedback("%s %s" % [
		LocalizationManager.get_text("ui.feedback.level_up"),
		str(current_level)
	])

## Exibe vitória ou derrota nesta camada somente quando habilitado.
##
## No protótipo atual, `ResultPanel` é a apresentação principal
## do encerramento da run.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	if not show_result_feedback:
		return

	if result_payload == null:
		return

	if result_payload.victory:
		show_feedback(LocalizationManager.get_text("ui.feedback.victory"))
	else:
		show_feedback(LocalizationManager.get_text("ui.feedback.defeat"))
