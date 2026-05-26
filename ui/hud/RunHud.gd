## HUD principal exibida durante uma run.
##
## Responsabilidades:
## - apresentar HP, XP, cooldown, tempo, moedas, nível e abates;
## - atualizar informações ao receber signals relevantes do gameplay;
## - executar atualização periódica de segurança para manter a UI sincronizada;
## - exibir uma mensagem simples sobre o estado atual da run.
##
## Este HUD apenas consulta e apresenta dados.
## Ele não altera estado do player, da arma ou da run.
extends CanvasLayer

@export_group("Visibility")

## Exibe ou oculta o bloco de vida da Queen.
@export var show_hp: bool = true

## Exibe ou oculta o bloco de experiência da run.
@export var show_xp: bool = true

## Exibe ou oculta o tempo restante ou decorrido.
@export var show_timer: bool = true

## Exibe ou oculta a quantidade de moedas coletadas.
@export var show_coins: bool = true

## Exibe ou oculta o nível atual alcançado na run.
@export var show_level: bool = true

## Exibe ou oculta o contador de inimigos derrotados.
@export var show_kills: bool = true

## Exibe ou oculta a mensagem textual inferior da HUD.
@export var show_message: bool = true

@export_group("Behavior")

## Intervalo entre atualizações gerais de segurança da HUD.
##
## Signals já atualizam dados imediatamente em eventos relevantes,
## mas esta atualização periódica mantém a interface coerente
## caso algum valor seja alterado sem emissão explícita.
@export var update_interval_seconds: float = 0.10

## Define qual tempo será mostrado:
## - true: tempo restante para vencer o mapa;
## - false: tempo já sobrevivido.
@export var show_remaining_time: bool = true

## Define se a HUD deve desaparecer quando o painel de resultado abrir.
##
## Mantido configurável porque, durante testes, pode ser útil observar
## os valores finais da run simultaneamente ao resultado.
@export var hide_when_result_panel_opens: bool = false

@export_group("Node Paths")

## Caminhos opcionais dos nodes do bloco de vida.
##
## Quando não forem configurados no Inspector, o script utiliza
## os caminhos padrão definidos na cena `RunHud.tscn`.
@export var hp_box_path: NodePath
@export var hp_label_path: NodePath
@export var hp_bar_path: NodePath

## Caminhos opcionais dos nodes do bloco de XP.
@export var xp_box_path: NodePath
@export var xp_label_path: NodePath
@export var xp_bar_path: NodePath

## Caminhos opcionais dos labels numéricos da run.
@export var timer_label_path: NodePath
@export var coins_label_path: NodePath
@export var level_label_path: NodePath
@export var kills_label_path: NodePath
@export var message_label_path: NodePath

## Caminhos opcionais dos nodes do cooldown da arma.
@export var cooldown_box_path: NodePath
@export var cooldown_label_path: NodePath
@export var cooldown_bar_path: NodePath

## Exibe ou oculta o bloco de cooldown do ataque atual.
@export var show_cooldown: bool = true

## Referências resolvidas do bloco de vida.
@onready var hp_box: Control = get_node_or_null(hp_box_path) as Control
@onready var hp_label: Label = get_node_or_null(hp_label_path) as Label
@onready var hp_bar: ProgressBar = get_node_or_null(hp_bar_path) as ProgressBar

## Referências resolvidas do bloco de experiência.
@onready var xp_box: Control = get_node_or_null(xp_box_path) as Control
@onready var xp_label: Label = get_node_or_null(xp_label_path) as Label
@onready var xp_bar: ProgressBar = get_node_or_null(xp_bar_path) as ProgressBar

## Referências resolvidas do bloco de cooldown da arma.
@onready var cooldown_box: Control = get_node_or_null(cooldown_box_path) as Control
@onready var cooldown_label: Label = get_node_or_null(cooldown_label_path) as Label
@onready var cooldown_bar: ProgressBar = get_node_or_null(cooldown_bar_path) as ProgressBar

## Referências resolvidas dos labels simples da HUD.
@onready var timer_label: Label = get_node_or_null(timer_label_path) as Label
@onready var coins_label: Label = get_node_or_null(coins_label_path) as Label
@onready var level_label: Label = get_node_or_null(level_label_path) as Label
@onready var kills_label: Label = get_node_or_null(kills_label_path) as Label
@onready var message_label: Label = get_node_or_null(message_label_path) as Label

## Acumulador utilizado pela atualização periódica da HUD.
var refresh_timer: float = 0.0

## Último tipo de resultado recebido ao finalizar a run.
##
## Usado como fallback textual caso o resultado não seja vitória
## nem derrota por algum fluxo futuro.
var latest_result_type: String = ""

## Último tempo restante informado pela arma atual.
var latest_cooldown_timer: float = 0.0

## Último progresso normalizado informado pela arma atual.
##
## Valor esperado entre `0.0` e `1.0`.
var latest_cooldown_progress_ratio: float = 1.0

## Inicializa a HUD, resolve nodes, configura barras e conecta events.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_resolve_missing_nodes()
	_apply_visibility()
	_configure_bars()
	_connect_events()
	_refresh_all()

	DeveloperAuditLogger.log_ui(
		"HUD inicializada.",
		"RunHud",
		{
			"show_hp": show_hp,
			"show_xp": show_xp,
			"show_cooldown": show_cooldown,
			"show_timer": show_timer,
			"show_coins": show_coins,
			"show_level": show_level,
			"show_kills": show_kills
		}
	)

## Atualiza periodicamente todos os elementos visuais da HUD.
##
## Este processo continua ativo mesmo quando a árvore está pausada,
## permitindo manter a interface coerente durante telas modais.
func _process(delta: float) -> void:
	refresh_timer += delta

	if refresh_timer < update_interval_seconds:
		return

	refresh_timer = 0.0
	_refresh_all()

## Conecta a HUD aos signals que podem alterar informações exibidas.
##
## As verificações com `is_connected()` impedem conexões duplicadas
## caso a cena seja reinicializada em fluxos de teste.
func _connect_events() -> void:
	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	if not GameEvents.player_died.is_connected(_on_player_died):
		GameEvents.player_died.connect(_on_player_died)

	if not GameEvents.run_xp_changed.is_connected(_on_run_xp_changed):
		GameEvents.run_xp_changed.connect(_on_run_xp_changed)

	if not GameEvents.run_enemy_killed.is_connected(_on_run_enemy_killed):
		GameEvents.run_enemy_killed.connect(_on_run_enemy_killed)

	if not GameEvents.run_coins_changed.is_connected(_on_run_coins_changed):
		GameEvents.run_coins_changed.connect(_on_run_coins_changed)

	if not GameEvents.run_timer_changed.is_connected(_on_run_timer_changed):
		GameEvents.run_timer_changed.connect(_on_run_timer_changed)

	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

	if not GameEvents.weapon_cooldown_changed.is_connected(_on_weapon_cooldown_changed):
		GameEvents.weapon_cooldown_changed.connect(_on_weapon_cooldown_changed)

## Atualiza todos os blocos visuais consultando player e run atuais.
##
## Os dados são obtidos por métodos de leitura utilizados também
## pelas ferramentas técnicas do protótipo.
func _refresh_all() -> void:
	_apply_visibility()

	var player_data: Dictionary = _get_player_debug_data()
	var run_data: Dictionary = _get_run_debug_data()

	_update_hp(player_data)
	_update_xp(run_data)
	_update_timer(run_data)
	_update_coins(run_data)
	_update_level(run_data)
	_update_kills(run_data)
	_update_cooldown()
	_update_message(run_data)

## Atualiza o label e a barra de cooldown do ataque.
##
## Quando o timer chega a zero, informa que a arma está pronta;
## durante a recarga, mostra o tempo restante em segundos.
func _update_cooldown() -> void:
	if not show_cooldown:
		return

	var cooldown_percent: float = clamp(latest_cooldown_progress_ratio, 0.0, 1.0) * 100.0

	if cooldown_label != null:
		if latest_cooldown_timer <= 0.0:
			cooldown_label.text = "%s: %s" % [
				LocalizationManager.get_text("ui.hud.attack"),
				LocalizationManager.get_text("ui.hud.attack_ready")
			]
		else:
			cooldown_label.text = "%s: %.1fs" % [
				LocalizationManager.get_text("ui.hud.attack"),
				latest_cooldown_timer
			]

	if cooldown_bar != null:
		cooldown_bar.max_value = 100.0
		cooldown_bar.value = cooldown_percent

## Atualiza vida atual e vida máxima da Queen.
func _update_hp(player_data: Dictionary) -> void:
	if not show_hp:
		return

	var current_hp: int = int(player_data.get("current_hp", 0))
	var max_hp: int = int(player_data.get("max_hp", 1))

	max_hp = max(1, max_hp)

	if hp_label != null:
		hp_label.text = "%s: %s / %s" % [
			LocalizationManager.get_text("ui.hud.hp"),
			str(current_hp),
			str(max_hp)
		]

	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = clamp(current_hp, 0, max_hp)

## Atualiza a experiência acumulada no nível atual.
##
## A XP mostrada aqui representa progressão interna da run
## até o próximo level-up, e não o total permanente salvo.
func _update_xp(run_data: Dictionary) -> void:
	if not show_xp:
		return

	var current_level_xp: int = int(run_data.get("current_level_xp", 0))
	var required_xp: int = int(run_data.get("xp_required_for_next_level", 1))

	required_xp = max(1, required_xp)

	if xp_label != null:
		xp_label.text = "%s: %s / %s" % [
			LocalizationManager.get_text("ui.hud.xp"),
			str(current_level_xp),
			str(required_xp)
		]

	if xp_bar != null:
		xp_bar.max_value = required_xp
		xp_bar.value = clamp(current_level_xp, 0, required_xp)

## Atualiza o contador temporal da run.
##
## O valor exibido depende de `show_remaining_time`.
func _update_timer(run_data: Dictionary) -> void:
	if not show_timer:
		return

	var elapsed_seconds: float = float(run_data.get("elapsed_seconds", 0.0))
	var remaining_seconds: float = float(run_data.get("remaining_seconds", 0.0))

	var selected_time: float = remaining_seconds if show_remaining_time else elapsed_seconds

	if timer_label != null:
		timer_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.timer"),
			_format_seconds(selected_time)
		]

## Atualiza apenas moedas efetivamente coletadas durante a run.
##
## Moedas ainda no chão não aparecem neste saldo.
func _update_coins(run_data: Dictionary) -> void:
	if not show_coins:
		return

	var coins: int = int(run_data.get("run_coins_collected", 0))

	if coins_label != null:
		coins_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.coins"),
			str(coins)
		]

## Atualiza o nível atual alcançado na run.
func _update_level(run_data: Dictionary) -> void:
	if not show_level:
		return

	var level: int = int(run_data.get("current_level", 1))

	if level_label != null:
		level_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.level"),
			str(level)
		]

## Atualiza a quantidade de inimigos derrotados na run.
func _update_kills(run_data: Dictionary) -> void:
	if not show_kills:
		return

	var kills: int = int(run_data.get("enemies_killed", 0))

	if kills_label != null:
		kills_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.kills"),
			str(kills)
		]

## Atualiza a mensagem de estado geral da run.
##
## Durante gameplay ativo, exibe a orientação principal.
## Após encerramento, informa vitória ou derrota.
func _update_message(run_data: Dictionary) -> void:
	if not show_message:
		return

	if message_label == null:
		return

	var is_finished: bool = bool(run_data.get("is_finished", false))
	var is_victory: bool = bool(run_data.get("is_victory", false))
	var is_defeat: bool = bool(run_data.get("is_defeat", false))

	if is_finished:
		if is_victory:
			message_label.text = LocalizationManager.get_text("ui.hud.victory")
		elif is_defeat:
			message_label.text = LocalizationManager.get_text("ui.hud.defeat")
		else:
			message_label.text = latest_result_type
	else:
		message_label.text = LocalizationManager.get_text("ui.hud.run_active")

## Aplica as opções de exibição configuradas no Inspector.
func _apply_visibility() -> void:
	if hp_box != null:
		hp_box.visible = show_hp

	if xp_box != null:
		xp_box.visible = show_xp

	if timer_label != null:
		timer_label.visible = show_timer

	if coins_label != null:
		coins_label.visible = show_coins

	if level_label != null:
		level_label.visible = show_level

	if kills_label != null:
		kills_label.visible = show_kills

	if message_label != null:
		message_label.visible = show_message

	if cooldown_box != null:
		cooldown_box.visible = show_cooldown

## Configura valores iniciais e apresentação das barras da HUD.
##
## Os valores efetivos são substituídos nas atualizações seguintes.
func _configure_bars() -> void:
	if hp_bar != null:
		hp_bar.min_value = 0
		hp_bar.max_value = 100
		hp_bar.value = 100
		hp_bar.show_percentage = false

	if xp_bar != null:
		xp_bar.min_value = 0
		xp_bar.max_value = 10
		xp_bar.value = 0
		xp_bar.show_percentage = false

	if cooldown_bar != null:
		cooldown_bar.min_value = 0
		cooldown_bar.max_value = 100
		cooldown_bar.value = 100
		cooldown_bar.show_percentage = false

## Resolve nodes não configurados explicitamente no Inspector.
##
## Os caminhos utilizados correspondem à estrutura padrão atual
## salva em `RunHud.tscn`.
func _resolve_missing_nodes() -> void:
	if hp_box == null:
		hp_box = get_node_or_null("MarginContainer/VBoxContainer/TopRow/HpBox") as Control

	if hp_label == null:
		hp_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/HpBox/HpLabel") as Label

	if hp_bar == null:
		hp_bar = get_node_or_null("MarginContainer/VBoxContainer/TopRow/HpBox/HpBar") as ProgressBar

	if xp_box == null:
		xp_box = get_node_or_null("MarginContainer/VBoxContainer/TopRow/XpBox") as Control

	if xp_label == null:
		xp_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/XpBox/XpLabel") as Label

	if xp_bar == null:
		xp_bar = get_node_or_null("MarginContainer/VBoxContainer/TopRow/XpBox/XpBar") as ProgressBar

	if timer_label == null:
		timer_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/TimerLabel") as Label

	if coins_label == null:
		coins_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/CoinsLabel") as Label

	if level_label == null:
		level_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/LevelLabel") as Label

	if kills_label == null:
		kills_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/KillsLabel") as Label

	if message_label == null:
		message_label = get_node_or_null("MarginContainer/VBoxContainer/MessageLabel") as Label

	if cooldown_box == null:
		cooldown_box = get_node_or_null("MarginContainer/VBoxContainer/TopRow/CooldownBox") as Control

	if cooldown_label == null:
		cooldown_label = get_node_or_null("MarginContainer/VBoxContainer/TopRow/CooldownBox/CooldownLabel") as Label

	if cooldown_bar == null:
		cooldown_bar = get_node_or_null("MarginContainer/VBoxContainer/TopRow/CooldownBox/CooldownBar") as ProgressBar

## Obtém dados atuais da Queen por meio do contrato técnico `get_debug_data()`.
##
## Apesar do nome histórico do método consultado, esses dados são usados
## também para alimentar a HUD funcional do protótipo.
func _get_player_debug_data() -> Dictionary:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return {}

	var player: Node = players[0]

	if player == null:
		return {}

	if not player.has_method("get_debug_data"):
		return {}

	var debug_data_variant: Variant = player.call("get_debug_data")

	if debug_data_variant is Dictionary:
		return debug_data_variant as Dictionary

	return {}

## Obtém dados atuais da run por meio do controller registrado.
func _get_run_debug_data() -> Dictionary:
	var run_controller: Node = RunQuery.get_run_controller(get_tree())

	if run_controller == null:
		return {}

	if not run_controller.has_method("get_debug_data"):
		return {}

	var debug_data_variant: Variant = run_controller.call("get_debug_data")

	if debug_data_variant is Dictionary:
		return debug_data_variant as Dictionary

	return {}

## Converte segundos em texto no formato `MM:SS`.
func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(max(0.0, seconds)))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]

## Atualiza imediatamente a HUD quando a Queen recebe dano.
func _on_player_damaged(
	_raw_damage: int,
	_final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	_refresh_all()

## Atualiza imediatamente a HUD quando a Queen morre.
func _on_player_died(_source_id: String) -> void:
	_refresh_all()

## Atualiza imediatamente XP e nível após alteração de progressão da run.
func _on_run_xp_changed(
	_run_xp_gained: int,
	_current_level: int,
	_current_level_xp: int,
	_xp_required_for_next_level: int
) -> void:
	_refresh_all()

## Atualiza imediatamente o contador de abates.
func _on_run_enemy_killed(_enemy_id: String, _enemies_killed: int) -> void:
	_refresh_all()

## Atualiza imediatamente o saldo de moedas coletadas.
func _on_run_coins_changed(_run_coins_collected: int, _run_coins_available: int) -> void:
	_refresh_all()

## Atualiza imediatamente o tempo mostrado na HUD.
func _on_run_timer_changed(
	_elapsed_seconds: float,
	_remaining_seconds: float,
	_duration_seconds: float
) -> void:
	_refresh_all()

## Trata a exibição da HUD quando o resultado final é publicado.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	latest_result_type = result_payload.result_type

	if hide_when_result_panel_opens:
		visible = false
	else:
		_refresh_all()

## Recebe do controller da arma o estado atual da recarga.
##
## Atualiza somente o bloco de cooldown, evitando atualizar
## toda a HUD a cada alteração contínua do timer da arma.
func _on_weapon_cooldown_changed(
	_weapon_id: String,
	cooldown_timer: float,
	_cooldown_seconds: float,
	progress_ratio: float
) -> void:
	latest_cooldown_timer = cooldown_timer
	latest_cooldown_progress_ratio = progress_ratio

	_update_cooldown()
