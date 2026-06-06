extends CanvasLayer

@export_group("Visibility")

@export var show_hp: bool = true

@export var show_xp: bool = true

@export var show_timer: bool = true

@export var show_coins: bool = true

@export var show_level: bool = true

@export var show_kills: bool = true

@export var show_message: bool = true

@export_group("Behavior")

@export var update_interval_seconds: float = 0.10

@export var show_remaining_time: bool = true

@export var hide_when_result_panel_opens: bool = false

@export_group("Node Paths")

@export var hp_box_path: NodePath
@export var hp_label_path: NodePath
@export var hp_bar_path: NodePath

@export var xp_box_path: NodePath
@export var xp_label_path: NodePath
@export var xp_bar_path: NodePath

@export var timer_label_path: NodePath
@export var coins_label_path: NodePath
@export var level_label_path: NodePath
@export var kills_label_path: NodePath
@export var message_label_path: NodePath

@export var cooldown_box_path: NodePath
@export var cooldown_label_path: NodePath
@export var cooldown_bar_path: NodePath

@export var show_cooldown: bool = true

@onready var hp_box: Control = get_node_or_null(hp_box_path) as Control
@onready var hp_label: Label = get_node_or_null(hp_label_path) as Label
@onready var hp_bar: ProgressBar = get_node_or_null(hp_bar_path) as ProgressBar

@onready var xp_box: Control = get_node_or_null(xp_box_path) as Control
@onready var xp_label: Label = get_node_or_null(xp_label_path) as Label
@onready var xp_bar: ProgressBar = get_node_or_null(xp_bar_path) as ProgressBar

@onready var cooldown_box: Control = get_node_or_null(cooldown_box_path) as Control
@onready var cooldown_label: Label = get_node_or_null(cooldown_label_path) as Label
@onready var cooldown_bar: ProgressBar = get_node_or_null(cooldown_bar_path) as ProgressBar

@onready var timer_label: Label = get_node_or_null(timer_label_path) as Label
@onready var coins_label: Label = get_node_or_null(coins_label_path) as Label
@onready var level_label: Label = get_node_or_null(level_label_path) as Label
@onready var kills_label: Label = get_node_or_null(kills_label_path) as Label
@onready var message_label: Label = get_node_or_null(message_label_path) as Label

var refresh_timer: float = 0.0

var latest_result_type: String = ""

var latest_cooldown_timer: float = 0.0

var latest_cooldown_progress_ratio: float = 1.0

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

func _process(delta: float) -> void:
	refresh_timer += delta

	if refresh_timer < update_interval_seconds:
		return

	refresh_timer = 0.0
	_refresh_all()

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

func _update_coins(run_data: Dictionary) -> void:
	if not show_coins:
		return

	var coins: int = int(run_data.get("run_coins_collected", 0))

	if coins_label != null:
		coins_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.coins"),
			str(coins)
		]

func _update_level(run_data: Dictionary) -> void:
	if not show_level:
		return

	var level: int = int(run_data.get("current_level", 1))

	if level_label != null:
		level_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.level"),
			str(level)
		]

func _update_kills(run_data: Dictionary) -> void:
	if not show_kills:
		return

	var kills: int = int(run_data.get("enemies_killed", 0))

	if kills_label != null:
		kills_label.text = "%s: %s" % [
			LocalizationManager.get_text("ui.hud.kills"),
			str(kills)
		]

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

func _format_seconds(seconds: float) -> String:
	var total_seconds: int = int(floor(max(0.0, seconds)))
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var remaining_seconds: int = total_seconds % 60

	return "%02d:%02d" % [minutes, remaining_seconds]

func _on_player_damaged(
	_raw_damage: int,
	_final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	_refresh_all()

func _on_player_died(_source_id: String) -> void:
	_refresh_all()

func _on_run_xp_changed(
	_run_xp_gained: int,
	_current_level: int,
	_current_level_xp: int,
	_xp_required_for_next_level: int
) -> void:
	_refresh_all()

func _on_run_enemy_killed(_enemy_id: String, _enemies_killed: int) -> void:
	_refresh_all()

func _on_run_coins_changed(_run_coins_collected: int, _run_coins_available: int) -> void:
	_refresh_all()

func _on_run_timer_changed(
	_elapsed_seconds: float,
	_remaining_seconds: float,
	_duration_seconds: float
) -> void:
	_refresh_all()

func _on_run_finished(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	latest_result_type = result_payload.result_type

	if hide_when_result_panel_opens:
		visible = false
	else:
		_refresh_all()

func _on_weapon_cooldown_changed(
	_weapon_id: String,
	cooldown_timer: float,
	_cooldown_seconds: float,
	progress_ratio: float
) -> void:
	latest_cooldown_timer = cooldown_timer
	latest_cooldown_progress_ratio = progress_ratio

	_update_cooldown()
