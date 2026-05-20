extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Panel/MarginContainer/VBoxContainer/SubtitleLabel
@onready var option_button_1: Button = $Panel/MarginContainer/VBoxContainer/OptionButton1
@onready var option_button_2: Button = $Panel/MarginContainer/VBoxContainer/OptionButton2
@onready var option_button_3: Button = $Panel/MarginContainer/VBoxContainer/OptionButton3

var current_options: Array[UpgradeDefinition] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_connect_buttons()

	if not GameEvents.run_level_up_started.is_connected(_on_run_level_up_started):
		GameEvents.run_level_up_started.connect(_on_run_level_up_started)

	if not GameEvents.run_level_up_completed.is_connected(_on_run_level_up_completed):
		GameEvents.run_level_up_completed.connect(_on_run_level_up_completed)

func _connect_buttons() -> void:
	if not option_button_1.pressed.is_connected(_on_option_1_pressed):
		option_button_1.pressed.connect(_on_option_1_pressed)

	if not option_button_2.pressed.is_connected(_on_option_2_pressed):
		option_button_2.pressed.connect(_on_option_2_pressed)

	if not option_button_3.pressed.is_connected(_on_option_3_pressed):
		option_button_3.pressed.connect(_on_option_3_pressed)

func _on_run_level_up_started(current_level: int, options: Array) -> void:
	current_options.clear()

	for option_variant: Variant in options:
		if option_variant is UpgradeDefinition:
			current_options.append(option_variant as UpgradeDefinition)

	visible = true

	title_label.text = "%s %s" % [
		LocalizationManager.get_text("ui.level_up.title"),
		str(current_level)
	]

	subtitle_label.text = LocalizationManager.get_text("ui.level_up.subtitle")

	_apply_option_to_button(option_button_1, 0)
	_apply_option_to_button(option_button_2, 1)
	_apply_option_to_button(option_button_3, 2)

	GameEvents.emit_debug("[LevelUpPanel] Aberto com %s opções." % str(current_options.size()))

func _on_run_level_up_completed(_current_level: int, _selected_upgrade_id: String) -> void:
	visible = false
	current_options.clear()

func _apply_option_to_button(button: Button, option_index: int) -> void:
	if option_index >= current_options.size():
		button.text = LocalizationManager.get_text("ui.level_up.option_missing")
		button.disabled = true
		return

	var upgrade: UpgradeDefinition = current_options[option_index]

	button.disabled = false
	button.text = "%s\n%s" % [
		LocalizationManager.get_text(upgrade.display_name_key),
		LocalizationManager.get_text(upgrade.description_key)
	]

func _select_option(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return

	var upgrade: UpgradeDefinition = current_options[index]

	if upgrade == null:
		return

	GameEvents.emit_debug("[LevelUpPanel] Upgrade selecionado: %s" % upgrade.id)
	GameEvents.run_level_up_option_selected.emit(upgrade)

func _on_option_1_pressed() -> void:
	_select_option(0)

func _on_option_2_pressed() -> void:
	_select_option(1)

func _on_option_3_pressed() -> void:
	_select_option(2)
