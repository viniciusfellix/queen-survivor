extends CanvasLayer

const DEFAULT_ICON_PATH: String = "res://assets/placeholders/upgrades/upgrade_default.png"

@export_group("Layout")

@export var center_panel_by_script: bool = true

@export var panel_size: Vector2 = Vector2(980.0, 460.0)

@export var panel_top_offset: float = 0.0

@export_group("Icons")

@export var default_icon: Texture2D

@export var hide_icon_when_missing: bool = false

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Panel/MarginContainer/VBoxContainer/SubtitleLabel

@onready var option_card_1: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard1
@onready var option_card_2: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard2
@onready var option_card_3: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/OptionCard3

var current_options: Array[UpgradeDefinition] = []

var cached_default_icon: Texture2D = null

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

func _connect_buttons() -> void:
	if option_card_1 != null and not option_card_1.pressed.is_connected(_on_option_1_pressed):
		option_card_1.pressed.connect(_on_option_1_pressed)

	if option_card_2 != null and not option_card_2.pressed.is_connected(_on_option_2_pressed):
		option_card_2.pressed.connect(_on_option_2_pressed)

	if option_card_3 != null and not option_card_3.pressed.is_connected(_on_option_3_pressed):
		option_card_3.pressed.connect(_on_option_3_pressed)

func _on_viewport_size_changed() -> void:
	_configure_layout()

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

func _on_run_level_up_completed(_current_level: int, _selected_upgrade_id: String) -> void:
	visible = false
	current_options.clear()

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

func _load_default_icon_if_needed() -> void:
	if default_icon != null:
		return

	if ResourceLoader.exists(DEFAULT_ICON_PATH):
		var loaded_resource: Resource = load(DEFAULT_ICON_PATH)

		if loaded_resource is Texture2D:
			cached_default_icon = loaded_resource as Texture2D

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

func _find_label(root: Node, node_name: String) -> Label:
	var found_node: Node = root.find_child(node_name, true, false)

	if found_node is Label:
		return found_node as Label

	return null

func _find_texture_rect(root: Node, node_name: String) -> TextureRect:
	var found_node: Node = root.find_child(node_name, true, false)

	if found_node is TextureRect:
		return found_node as TextureRect

	return null

func _on_option_1_pressed() -> void:
	_select_option(0)

func _on_option_2_pressed() -> void:
	_select_option(1)

func _on_option_3_pressed() -> void:
	_select_option(2)
