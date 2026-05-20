extends Node

@export var run_state: RunState

@export var level_up_option_count: int = 3
@export var upgrade_pool: Array[UpgradeDefinition] = []

var pending_level_ups: int = 0
var current_level_up_options: Array[UpgradeDefinition] = []
var is_level_up_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run_controller")

	if run_state == null:
		run_state = RunState.new()

	_load_default_upgrade_pool_if_empty()
	_connect_events()

	GameEvents.emit_debug("[RunController] Run iniciada.")

func _process(delta: float) -> void:
	if run_state == null:
		return

	if run_state.is_paused or run_state.is_victory or run_state.is_defeat:
		return

	run_state.elapsed_seconds += delta

func get_run_state() -> RunState:
	return run_state

func get_debug_data() -> Dictionary:
	if run_state == null:
		return {
			"has_run_state": false
		}

	return {
		"has_run_state": true,
		"elapsed_seconds": run_state.elapsed_seconds,
		"run_xp_gained": run_state.run_xp_gained,
		"current_level": run_state.current_level,
		"current_level_xp": run_state.current_level_xp,
		"xp_required_for_next_level": run_state.xp_required_for_next_level,
		"xp_progress_ratio": run_state.get_xp_progress_ratio(),
		"enemies_killed": run_state.enemies_killed,
		"level_reached": run_state.level_reached,
		"run_coins_collected": run_state.run_coins_collected,
		"run_coins_spent": run_state.run_coins_spent,
		"run_coins_available": run_state.get_run_coins_available(),
		"is_paused": run_state.is_paused,
		"is_level_up_active": is_level_up_active,
		"pending_level_ups": pending_level_ups
	}

func _connect_events() -> void:
	if not GameEvents.enemy_died.is_connected(_on_enemy_died):
		GameEvents.enemy_died.connect(_on_enemy_died)

	if not GameEvents.run_level_up_option_selected.is_connected(_on_level_up_option_selected):
		GameEvents.run_level_up_option_selected.connect(_on_level_up_option_selected)
	
	if not GameEvents.run_coin_collected.is_connected(_on_run_coin_collected):
		GameEvents.run_coin_collected.connect(_on_run_coin_collected)

func _on_run_coin_collected(value: int, coin_global_position: Vector2) -> void:
	if run_state == null:
		return

	if value <= 0:
		return

	run_state.add_coins(value)

	GameEvents.run_coins_changed.emit(
		run_state.run_coins_collected,
		run_state.get_run_coins_available()
	)

	GameEvents.emit_debug("[RunController] Moeda coletada: value=%s pos=%s total=%s available=%s" % [
		str(value),
		str(coin_global_position),
		str(run_state.run_coins_collected),
		str(run_state.get_run_coins_available())
	])

func _on_enemy_died(
	enemy_id: String,
	source_id: String,
	xp_reward: int,
	enemy_global_position: Vector2,
	_coin_drop_chance: float,
	_coin_drop_value: int
) -> void:
	if run_state == null:
		return

	if run_state.is_victory or run_state.is_defeat:
		return

	run_state.add_enemy_kill()
	var levels_gained: int = run_state.add_xp(xp_reward)

	if levels_gained > 0:
		pending_level_ups += levels_gained

	GameEvents.run_enemy_killed.emit(enemy_id, run_state.enemies_killed)

	GameEvents.run_xp_changed.emit(
		run_state.run_xp_gained,
		run_state.current_level,
		run_state.current_level_xp,
		run_state.xp_required_for_next_level
	)

	GameEvents.emit_debug("[RunController] Inimigo morto: %s fonte=%s xp=%s pos=%s total_kills=%s run_xp=%s level=%s xp=%s/%s levels_gained=%s" % [
		enemy_id,
		source_id,
		str(xp_reward),
		str(enemy_global_position),
		str(run_state.enemies_killed),
		str(run_state.run_xp_gained),
		str(run_state.current_level),
		str(run_state.current_level_xp),
		str(run_state.xp_required_for_next_level),
		str(levels_gained)
	])

	if pending_level_ups > 0 and not is_level_up_active:
		_start_next_level_up()

func _start_next_level_up() -> void:
	if run_state == null:
		return

	if pending_level_ups <= 0:
		return

	is_level_up_active = true
	run_state.is_paused = true
	get_tree().paused = true

	current_level_up_options = LevelUpOptionService.generate_options(upgrade_pool, level_up_option_count)

	GameEvents.emit_debug("[RunController] Level-up iniciado. level=%s options=%s" % [
		str(run_state.current_level),
		str(_get_option_ids(current_level_up_options))
	])

	GameEvents.run_level_up_started.emit(run_state.current_level, current_level_up_options)

func _on_level_up_option_selected(upgrade: UpgradeDefinition) -> void:
	if not is_level_up_active:
		return

	if upgrade == null or not upgrade.is_valid_definition():
		GameEvents.emit_debug("[RunController] Upgrade inválido selecionado.")
		return

	_apply_upgrade(upgrade)

	pending_level_ups = max(0, pending_level_ups - 1)

	GameEvents.run_level_up_completed.emit(run_state.current_level, upgrade.id)

	GameEvents.emit_debug("[RunController] Level-up concluído. upgrade=%s pending=%s" % [
		upgrade.id,
		str(pending_level_ups)
	])

	if pending_level_ups > 0:
		_start_next_level_up()
	else:
		is_level_up_active = false
		current_level_up_options.clear()

		if run_state != null:
			run_state.is_paused = false

		get_tree().paused = false

func _apply_upgrade(upgrade: UpgradeDefinition) -> void:
	var player: Node = _get_player()

	if player != null and player.has_method("apply_run_upgrade"):
		player.call("apply_run_upgrade", upgrade)
	else:
		GameEvents.emit_debug("[RunController] Player não encontrado ou sem apply_run_upgrade.")

func _get_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return null

	return players[0]

func _load_default_upgrade_pool_if_empty() -> void:
	if not upgrade_pool.is_empty():
		return

	var default_paths: Array[String] = [
		"res://data/upgrades/upgrade_weapon_damage_flat.tres",
		"res://data/upgrades/upgrade_weapon_cooldown_percent.tres",
		"res://data/upgrades/upgrade_player_move_speed_percent.tres",
		"res://data/upgrades/upgrade_player_max_hp_flat.tres"
	]

	for path: String in default_paths:
		if not ResourceLoader.exists(path):
			continue

		var resource: Resource = load(path)

		if resource is UpgradeDefinition:
			upgrade_pool.append(resource as UpgradeDefinition)

	GameEvents.emit_debug("[RunController] Upgrade pool carregada: %s opções." % str(upgrade_pool.size()))

func _get_option_ids(options: Array[UpgradeDefinition]) -> String:
	var ids: Array[String] = []

	for option: UpgradeDefinition in options:
		if option == null:
			continue

		ids.append(option.id)

	return ", ".join(ids)
