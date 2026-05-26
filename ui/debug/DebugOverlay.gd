## Overlay técnico de leitura rápida durante testes de gameplay.
##
## Responsabilidades:
## - apresentar informações selecionáveis do input, player, run e save;
## - permitir habilitar somente as seções úteis para cada teste;
## - acompanhar a última animação Spine publicada pela Gaia;
## - reduzir poluição visual durante runs de validação.
##
## Este overlay é somente leitura.
## Ele não força resultados, não altera save e não modifica gameplay.
extends CanvasLayer

@export_group("Master")

## Habilita ou desabilita completamente a exibição do overlay.
@export var debug_enabled: bool = true

## Define se o título principal será exibido.
@export var show_title: bool = true

## Define se divisores textuais serão exibidos entre seções.
@export var show_separators: bool = true

@export_group("Panel Layout")

## Posição do painel técnico na viewport.
@export var panel_position: Vector2 = Vector2(16.0, 16.0)

## Tamanho reservado para o painel técnico.
@export var panel_size: Vector2 = Vector2(600.0, 420.0)

## Margem interna utilizada entre o painel e seu conteúdo.
@export var panel_margin: float = 8.0

@export_group("Sections")

## Exibe direções atuais de movimento e mira vindas do InputManager.
@export var show_input_section: bool = true

## Exibe a última animação Spine publicada pela Gaia.
@export var show_animation_section: bool = true

## Exibe dados principais do player, como HP, estado e velocidade.
@export var show_player_core_section: bool = true

## Exibe informações de dano recebido e causa de morte.
@export var show_player_combat_section: bool = true

## Exibe vetores e posição detalhada do player.
##
## Fica desligada por padrão para reduzir tamanho do overlay.
@export var show_player_direction_section: bool = false

## Exibe tempo, duração e mapa da run.
@export var show_run_timer_section: bool = true

## Exibe XP, level, abates e estado de level-up.
@export var show_run_progression_section: bool = true

## Exibe moedas coletadas, disponíveis e gastas.
@export var show_run_economy_section: bool = true

## Exibe resultado final e recompensa calculada.
@export var show_run_result_section: bool = false

## Exibe totais persistentes do save.
@export var show_save_section: bool = false

@export var show_technical_section: bool = false

@export_group("World Enemy Links")

## Habilita linhas técnicas entre a Gaia e inimigos ativos.
##
## A ferramenta fica desabilitada por padrão para não poluir
## a visualização durante testes que não dependem desse diagnóstico.
@export var show_enemy_links: bool = false

## Grupo utilizado para localizar a personagem controlada.
@export var enemy_links_player_group_name: String = "player"

## Grupo utilizado para localizar inimigos instanciados.
@export var enemy_links_enemy_group_name: String = "enemy"

## Cor aplicada às linhas e aos marcadores opcionais.
@export var enemy_link_color: Color = Color(1.0, 0.18, 0.18, 0.70)

## Espessura visual das linhas desenhadas.
@export var enemy_link_width: float = 2.0

## Exibe círculos nas posições da Gaia e dos inimigos.
@export var show_enemy_link_markers: bool = false

## Tamanho do marcador opcional da Gaia.
@export var player_link_marker_radius: float = 5.0

## Tamanho do marcador opcional de cada inimigo.
@export var enemy_link_marker_radius: float = 4.0

@export_group("Formatting")

## Define se vetores devem ser apresentados em formato numérico compacto.
@export var compact_vectors: bool = true

## Quantidade de casas decimais utilizadas na formatação numérica.
@export var decimal_places: int = 2

## Limite de mapas concluídos mostrados diretamente no overlay.
@export var max_completed_maps_to_show: int = 3

## Painel visual que contém todo o conteúdo textual do overlay.
@onready var panel: Panel = get_node_or_null("Panel") as Panel

## Label principal onde todas as linhas técnicas são renderizadas.
@onready var label: Label = _resolve_label()

## Node dedicado ao desenho opcional das conexões entre player e inimigos.
@onready var enemy_link_drawer: Node2D = get_node_or_null("EnemyLinkDrawer") as Node2D

## Última animação Spine publicada pelo adapter visual da Gaia.
var last_animation_name: String = ""

## Impede repetição contínua de warning caso o node visual
## das linhas tenha sido removido acidentalmente da cena.
var warned_missing_enemy_link_drawer: bool = false

## Configura o painel e conecta o signal de animação utilizado na leitura técnica.
func _ready() -> void:
	_configure_panel()
	_sync_enemy_link_drawer()

	if not GameEvents.spine_animation_changed.is_connected(_on_spine_animation_changed):
		GameEvents.spine_animation_changed.connect(_on_spine_animation_changed)

	if label == null:
		push_warning("[DebugOverlay] Label não encontrado.")
	else:
		DeveloperAuditLogger.log_ui(
			"Overlay técnico inicializado.",
			"DebugOverlay",
			{
				"label_name": label.name
			}
		)

## Reconstrói o conteúdo textual exibido a cada frame.
##
## Como as seções podem ser alternadas diretamente no Inspector,
## cada bloco só adiciona suas linhas quando estiver habilitado.
func _process(_delta: float) -> void:
	if panel != null:
		panel.visible = debug_enabled
	
	_sync_enemy_link_drawer()
	
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

## Adiciona informações atuais de movimento e mira.
func _append_input_section(lines: Array[String]) -> void:
	var move_direction: Vector2 = InputManager.get_move_direction()
	var aim_direction: Vector2 = InputManager.get_aim_direction()

	lines.append("INPUT")
	lines.append("Move: %s" % _format_vector(move_direction))
	lines.append("Aim: %s" % _format_vector(aim_direction))

## Adiciona a última animação Spine publicada pela Gaia.
func _append_animation_section(lines: Array[String]) -> void:
	lines.append("ANIMATION")
	lines.append("Last Spine: %s" % last_animation_name)

## Adiciona informações principais do runtime state do player.
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

## Adiciona dados de combate recebidos pelo player.
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

## Adiciona direções e posição mundial do player.
##
## Seção útil para validação de mira, facing e movimentação,
## mas normalmente desativada durante testes gerais.
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

## Adiciona informações temporais e identificação do mapa atual.
func _append_run_timer_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN TIMER")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Map: %s" % str(data.get("map_id", "")))
	lines.append("Time: %s" % _format_seconds(float(data.get("elapsed_seconds", 0.0))))
	lines.append("Remaining: %s" % _format_seconds(float(data.get("remaining_seconds", 0.0))))
	lines.append("Duration: %s" % _format_seconds(float(data.get("map_duration_seconds", 0.0))))

## Adiciona dados de XP, level, abates e seleção de upgrades.
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

## Adiciona informações econômicas da run atual.
func _append_run_economy_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("RUN ECONOMY")

	if data.is_empty():
		lines.append("RunController: não encontrado")
		return

	lines.append("Run Coins: %s" % str(data.get("run_coins_collected", 0)))
	lines.append("Coins Available: %s" % str(data.get("run_coins_available", 0)))
	lines.append("Coins Spent: %s" % str(data.get("run_coins_spent", 0)))

## Adiciona dados finais da run após vitória ou derrota.
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

## Adiciona informações persistentes do save atual.
func _append_save_section(lines: Array[String], data: Dictionary) -> void:
	lines.append("SAVE")

	if data.is_empty() or not bool(data.get("has_save_data", false)):
		lines.append("Save: não encontrado")
		return

	lines.append("Total XP: %s" % str(data.get("total_xp", 0)))
	lines.append("Total Money: %s" % str(data.get("total_money", 0)))
	lines.append("Completed Maps: %s" % _format_limited_array(data.get("completed_maps", []), max_completed_maps_to_show))
	lines.append("SFW: %s" % str(data.get("sfw_enabled", true)))

## Adiciona verificações técnicas gerais da cena atual.
func _append_technical_section(
	lines: Array[String],
	player_data: Dictionary,
	run_data: Dictionary,
	save_data: Dictionary
) -> void:
	lines.append("TECHNICAL")
	lines.append("Has Player Data: %s" % str(not player_data.is_empty()))
	lines.append("Has Run Data: %s" % str(not run_data.is_empty()))
	lines.append("Has Save Data: %s" % str(bool(save_data.get("has_save_data", false))))
	lines.append("Paused Tree: %s" % str(get_tree().paused))
	lines.append("Panel Size: %s" % _format_vector(panel_size))

## Adiciona divisor textual antes de uma seção, quando habilitado.
func _append_separator(lines: Array[String]) -> void:
	if not show_separators:
		return

	if lines.is_empty():
		return

	lines.append("--------------------")

## Configura posição, tamanho e comportamento visual do painel.
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

## Resolve o label principal pelo caminho esperado ou por busca recursiva.
func _resolve_label() -> Label:
	var direct_label: Label = get_node_or_null("Panel/MarginContainer/Label") as Label

	if direct_label != null:
		return direct_label

	var found_label: Label = _find_first_label(self)

	if found_label != null:
		return found_label

	return null

## Procura recursivamente o primeiro Label existente em uma subárvore.
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

## Retorna o primeiro player registrado na cena atual.
func _get_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return null

	return players[0]

## Retorna o controller da run ativa por meio do helper compartilhado.
func _get_run_controller() -> Node:
	return RunQuery.get_run_controller(get_tree())

## Consulta um node que exponha o contrato técnico `get_debug_data()`.
func _get_debug_data_from_node(node: Node) -> Dictionary:
	if node == null:
		return {}

	if not node.has_method("get_debug_data"):
		return {}

	var debug_data_variant: Variant = node.call("get_debug_data")

	if debug_data_variant is Dictionary:
		return debug_data_variant as Dictionary

	return {}

## Formata vetores para apresentação no overlay.
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

## Formata número decimal utilizando a precisão configurada no Inspector.
func _format_float(value: float) -> String:
	var safe_decimal_places: int = max(0, decimal_places)
	var format_string: String = "%." + str(safe_decimal_places) + "f"

	return format_string % value

## Converte segundos para texto no formato `MM:SS`.
func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(max(0.0, seconds)))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]

## Formata uma lista exibindo apenas a quantidade configurada de itens.
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

## Envia ao drawer visual as configurações atuais das linhas de debug.
##
## O `debug_enabled` funciona como chave mestra:
## mesmo que `show_enemy_links` esteja marcado, nenhuma linha é exibida
## quando o overlay técnico inteiro estiver desabilitado.
func _sync_enemy_link_drawer() -> void:
	if enemy_link_drawer == null:
		if debug_enabled and show_enemy_links and not warned_missing_enemy_link_drawer:
			push_warning("[DebugOverlay] EnemyLinkDrawer não encontrado na cena.")
			warned_missing_enemy_link_drawer = true

		return

	warned_missing_enemy_link_drawer = false

	if not enemy_link_drawer.has_method("configure"):
		if debug_enabled and show_enemy_links and not warned_missing_enemy_link_drawer:
			push_warning("[DebugOverlay] EnemyLinkDrawer não implementa configure().")
			warned_missing_enemy_link_drawer = true

		return

	enemy_link_drawer.call(
		"configure",
		debug_enabled and show_enemy_links,
		enemy_links_player_group_name,
		enemy_links_enemy_group_name,
		enemy_link_color,
		enemy_link_width,
		show_enemy_link_markers,
		player_link_marker_radius,
		enemy_link_marker_radius
	)

## Armazena a última animação publicada pela Gaia para exibição técnica.
func _on_spine_animation_changed(animation_name: String) -> void:
	last_animation_name = animation_name
