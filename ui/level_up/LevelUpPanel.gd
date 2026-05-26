## Painel modal de escolha de upgrade durante um level-up.
##
## Responsabilidades:
## - receber opções geradas pelo `RunController`;
## - exibir até três cards de melhoria;
## - mostrar ícone, nome, descrição e próximo nível do upgrade;
## - centralizar o painel na viewport;
## - publicar a opção escolhida para continuidade da run.
##
## Este painel não aplica upgrades diretamente.
## A aplicação real ocorre após o signal `run_level_up_option_selected`.
extends CanvasLayer

## Caminho do ícone placeholder utilizado quando um upgrade
## não possui imagem específica configurada.
const DEFAULT_ICON_PATH: String = "res://assets/placeholders/upgrades/upgrade_default.png"

@export_group("Layout")

## Define se a posição central do painel será calculada por script.
@export var center_panel_by_script: bool = true

## Tamanho atual do painel de escolha.
@export var panel_size: Vector2 = Vector2(980.0, 460.0)

## Deslocamento vertical adicional aplicado após centralização.
@export var panel_top_offset: float = 0.0

@export_group("Icons")

## Ícone padrão configurável diretamente pelo Inspector.
@export var default_icon: Texture2D

## Define se o espaço do ícone deve desaparecer
## quando nenhuma textura estiver disponível.
@export var hide_icon_when_missing: bool = false

## Referências dos nodes estruturais do painel.
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Panel/MarginContainer/VBoxContainer/SubtitleLabel

## Cards fixos atualmente suportados pelo protótipo.
##
## A governança prevê inicialmente três opções por level-up.
@onready var option_card_1: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard1
@onready var option_card_2: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard2
@onready var option_card_3: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard3

## Opções atualmente disponíveis para escolha pelo jogador.
var current_options: Array[UpgradeDefinition] = []

## Ícone placeholder carregado em memória para reutilização nos cards.
var cached_default_icon: Texture2D = null

## Inicializa o painel oculto, prepara layout, buttons e events.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_load_default_icon_if_needed()
	_configure_layout()
	_connect_buttons()

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if not GameEvents.run_level_up_started.is_connected(_on_run_level_up_started):
		GameEvents.run_level_up_started.connect(_on_run_level_up_started)

	if not GameEvents.run_level_up_completed.is_connected(_on_run_level_up_completed):
		GameEvents.run_level_up_completed.connect(_on_run_level_up_completed)

## Conecta cada card fixo ao índice correspondente da lista de opções.
func _connect_buttons() -> void:
	if option_card_1 != null and not option_card_1.pressed.is_connected(_on_option_1_pressed):
		option_card_1.pressed.connect(_on_option_1_pressed)

	if option_card_2 != null and not option_card_2.pressed.is_connected(_on_option_2_pressed):
		option_card_2.pressed.connect(_on_option_2_pressed)

	if option_card_3 != null and not option_card_3.pressed.is_connected(_on_option_3_pressed):
		option_card_3.pressed.connect(_on_option_3_pressed)

## Recalcula a posição do painel quando a viewport muda de tamanho.
func _on_viewport_size_changed() -> void:
	_configure_layout()

## Centraliza manualmente o painel de escolhas na viewport.
##
## Esta correção garante que o painel permaneça no centro,
## independentemente de offsets residuais salvos na cena.
func _configure_layout() -> void:
	if panel == null:
		return

	if not center_panel_by_script:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	panel.position = Vector2(
		(viewport_size.x - panel_size.x) * 0.5,
		((viewport_size.y - panel_size.y) * 0.5) + panel_top_offset
	)

## Abre o painel ao iniciar um level-up.
##
## Recebe opções genéricas por signal e mantém apenas recursos
## válidos do tipo `UpgradeDefinition`.
func _on_run_level_up_started(current_level: int, options: Array) -> void:
	current_options.clear()

	for option_variant: Variant in options:
		if option_variant is UpgradeDefinition:
			current_options.append(option_variant as UpgradeDefinition)

	visible = true
	_configure_layout()

	title_label.text = "%s %s" % [
		LocalizationManager.get_text("ui.level_up.title"),
		str(current_level)
	]

	subtitle_label.text = LocalizationManager.get_text("ui.level_up.subtitle")

	_apply_option_to_card(option_card_1, 0)
	_apply_option_to_card(option_card_2, 1)
	_apply_option_to_card(option_card_3, 2)

	DeveloperAuditLogger.log_upgrade(
		"Painel aberto: level=%s options=%s" % [
			str(current_level),
			str(current_options.size())
		],
		"LevelUpPanel",
		{
			"level": current_level,
			"options_count": current_options.size()
		}
	)

## Fecha o painel depois que a escolha foi processada pela run.
func _on_run_level_up_completed(_current_level: int, _selected_upgrade_id: String) -> void:
	visible = false
	current_options.clear()

## Preenche um card com a opção correspondente ao índice informado.
##
## Quando não existe opção naquele índice, desabilita o card
## e apresenta o estado de indisponibilidade.
func _apply_option_to_card(card: Button, option_index: int) -> void:
	if card == null:
		return

	card.text = ""

	if option_index >= current_options.size():
		card.disabled = true
		_set_card_text(card, LocalizationManager.get_text("ui.level_up.option_missing"), "", "")
		_set_card_icon(card, null)
		return

	var upgrade: UpgradeDefinition = current_options[option_index]

	card.disabled = false

	var upgrade_name: String = LocalizationManager.get_text(upgrade.display_name_key)
	var upgrade_description: String = LocalizationManager.get_text(upgrade.description_key)
	var badge_text: String = _get_badge_text(upgrade)

	_set_card_text(card, upgrade_name, upgrade_description, badge_text)
	_set_card_icon(card, upgrade.icon)

## Atualiza os labels internos de um card.
##
## Os labels são encontrados por nome para manter o método reutilizável
## entre os três cards fixos da cena.
func _set_card_text(card: Button, upgrade_name: String, description: String, badge: String) -> void:
	var name_label: Label = _find_label(card, "NameLabel")
	var description_label: Label = _find_label(card, "DescriptionLabel")
	var badge_label: Label = _find_label(card, "BadgeLabel")

	if name_label != null:
		name_label.text = upgrade_name

	if description_label != null:
		description_label.text = description

	if badge_label != null:
		badge_label.text = badge

## Define o ícone exibido em um card.
##
## Prioridade:
## 1. textura específica do upgrade;
## 2. textura padrão;
## 3. ocultação ou espaço vazio conforme configuração.
func _set_card_icon(card: Button, texture: Texture2D) -> void:
	var icon_texture: TextureRect = _find_texture_rect(card, "IconTexture")

	if icon_texture == null:
		push_warning("[LevelUpPanel] IconTexture não encontrado no card: %s" % card.name)
		return

	var final_texture: Texture2D = texture

	if final_texture == null:
		final_texture = _get_default_icon()

	if final_texture == null:
		icon_texture.visible = not hide_icon_when_missing
		return

	icon_texture.visible = true
	icon_texture.texture = final_texture
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.custom_minimum_size = Vector2(56.0, 56.0)

## Retorna o ícone padrão atual, carregando-o somente quando necessário.
func _get_default_icon() -> Texture2D:
	if default_icon != null:
		return default_icon

	if cached_default_icon != null:
		return cached_default_icon

	if ResourceLoader.exists(DEFAULT_ICON_PATH):
		var loaded_resource: Resource = load(DEFAULT_ICON_PATH)

		if loaded_resource is Texture2D:
			cached_default_icon = loaded_resource as Texture2D
			return cached_default_icon

	return null

## Pré-carrega o ícone padrão durante a inicialização do painel.
func _load_default_icon_if_needed() -> void:
	if default_icon != null:
		return

	if ResourceLoader.exists(DEFAULT_ICON_PATH):
		var loaded_resource: Resource = load(DEFAULT_ICON_PATH)

		if loaded_resource is Texture2D:
			cached_default_icon = loaded_resource as Texture2D

## Monta o badge que indica o nível/stack resultante da escolha.
##
## Upgrades configurados sem badge retornam texto vazio.
func _get_badge_text(upgrade: UpgradeDefinition) -> String:
	if upgrade == null:
		return ""

	if not upgrade.show_level_badge:
		return ""

	var next_level: int = _get_next_upgrade_level(upgrade.id)

	return "%s %s" % [
		LocalizationManager.get_text("ui.level_up.badge_level"),
		str(next_level)
	]

## Consulta ao `RunController` qual será o próximo nível do upgrade.
##
## Utiliza valor `1` como fallback seguro caso o controller
## ainda não esteja disponível ou não exponha esse contrato.
func _get_next_upgrade_level(upgrade_id: String) -> int:
	var run_controller: Node = RunQuery.get_run_controller(get_tree())

	if run_controller == null:
		return 1

	if not run_controller.has_method("get_next_upgrade_level"):
		return 1

	var level_variant: Variant = run_controller.call("get_next_upgrade_level", upgrade_id)

	if level_variant is int:
		return int(level_variant)

	return 1

## Publica a opção escolhida pelo jogador.
##
## A seleção não aplica efeitos diretamente neste painel;
## o `RunController` recebe o signal e executa a aplicação apropriada.
func _select_option(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return

	var upgrade: UpgradeDefinition = current_options[index]

	if upgrade == null:
		return

	DeveloperAuditLogger.log_upgrade(
		"Opção selecionada: %s" % upgrade.id,
		"LevelUpPanel",
		{
			"upgrade_id": upgrade.id,
			"option_index": index
		}
	)

	GameEvents.run_level_up_option_selected.emit(upgrade)

## Procura recursivamente um label de nome conhecido dentro de um card.
func _find_label(root: Node, node_name: String) -> Label:
	var found_node: Node = root.find_child(node_name, true, false)

	if found_node is Label:
		return found_node as Label

	return null

## Procura recursivamente o node de textura de um card.
func _find_texture_rect(root: Node, node_name: String) -> TextureRect:
	var found_node: Node = root.find_child(node_name, true, false)

	if found_node is TextureRect:
		return found_node as TextureRect

	return null

## Seleciona a primeira opção apresentada.
func _on_option_1_pressed() -> void:
	_select_option(0)

## Seleciona a segunda opção apresentada.
func _on_option_2_pressed() -> void:
	_select_option(1)

## Seleciona a terceira opção apresentada.
func _on_option_3_pressed() -> void:
	_select_option(2)
