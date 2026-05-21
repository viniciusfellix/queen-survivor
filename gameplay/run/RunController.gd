extends Node

@export var run_state: RunState
@export var map_definition: MapDefinition

@export var level_up_option_count: int = 3
@export var upgrade_pool: Array[UpgradeDefinition] = []

@export var finish_run_pauses_tree: bool = true
@export var defeat_result_delay_seconds: float = 0.75

var pending_level_ups: int = 0
var current_level_up_options: Array[UpgradeDefinition] = []
var is_level_up_active: bool = false
var result_payload: RunResultPayload = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run_controller")

	if run_state == null:
		run_state = RunState.new()

	if map_definition != null:
		run_state.setup_from_map(map_definition)

	_load_default_upgrade_pool_if_empty()
	_connect_events()

	GameEvents.emit_debug("[RunController] Run iniciada. map=%s duration=%s" % [
		run_state.map_id,
		str(run_state.map_duration_seconds)
	])

func _process(delta: float) -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	if run_state.is_paused or run_state.is_victory or run_state.is_defeat:
		return

	run_state.elapsed_seconds += delta

	GameEvents.run_timer_changed.emit(
		run_state.elapsed_seconds,
		run_state.get_remaining_seconds(),
		run_state.map_duration_seconds
	)

	if run_state.elapsed_seconds >= run_state.map_duration_seconds:
		_finish_victory()

func get_run_state() -> RunState:
	return run_state

func get_map_definition() -> MapDefinition:
	return map_definition

func get_result_payload() -> RunResultPayload:
	return result_payload

func get_debug_data() -> Dictionary:
	if run_state == null:
		return {
			"has_run_state": false
		}

	return {
		"has_run_state": true,
		"map_id": run_state.map_id,
		"queen_id": run_state.queen_id,
		"elapsed_seconds": run_state.elapsed_seconds,
		"remaining_seconds": run_state.get_remaining_seconds(),
		"map_duration_seconds": run_state.map_duration_seconds,
		"time_progress_ratio": run_state.get_time_progress_ratio(),
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
		"pending_level_ups": pending_level_ups,
		"is_finished": run_state.is_finished,
		"is_victory": run_state.is_victory,
		"is_defeat": run_state.is_defeat,
		"result_type": run_state.result_type,
		"final_money_reward": run_state.final_money_reward,
		"death_cause": run_state.death_cause
	}

func _connect_events() -> void:
	if not GameEvents.enemy_died.is_connected(_on_enemy_died):
		GameEvents.enemy_died.connect(_on_enemy_died)

	if not GameEvents.run_level_up_option_selected.is_connected(_on_level_up_option_selected):
		GameEvents.run_level_up_option_selected.connect(_on_level_up_option_selected)

	if not GameEvents.run_coin_collected.is_connected(_on_run_coin_collected):
		GameEvents.run_coin_collected.connect(_on_run_coin_collected)

	if not GameEvents.player_died.is_connected(_on_player_died):
		GameEvents.player_died.connect(_on_player_died)

	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	if not GameEvents.enemy_damaged.is_connected(_on_enemy_damaged):
		GameEvents.enemy_damaged.connect(_on_enemy_damaged)

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

	if run_state.is_finished or run_state.is_victory or run_state.is_defeat:
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

func _on_run_coin_collected(value: int, coin_global_position: Vector2) -> void:
	if run_state == null:
		return

	if run_state.is_finished:
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

func _on_player_damaged(_raw_damage: int, final_damage: int, _current_hp: int, _max_hp: int, _source_id: String) -> void:
	if run_state == null:
		return

	run_state.add_damage_taken(final_damage)

func _on_enemy_damaged(_enemy_id: String, _raw_damage: int, final_damage: int, _current_hp: int, _max_hp: int, _source_id: String) -> void:
	if run_state == null:
		return

	run_state.add_damage_dealt(final_damage)

func _on_player_died(source_id: String) -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	GameEvents.emit_debug("[RunController] Derrota agendada. source=%s delay=%s" % [
		source_id,
		str(defeat_result_delay_seconds)
	])

	if defeat_result_delay_seconds <= 0.0:
		_finish_defeat(source_id)
		return

	var defeat_timer: SceneTreeTimer = get_tree().create_timer(defeat_result_delay_seconds)
	defeat_timer.timeout.connect(func() -> void:
		_finish_defeat(source_id)
	)

func _finish_victory() -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	run_state.elapsed_seconds = run_state.map_duration_seconds
	run_state.mark_victory()

	_finish_run()

func _finish_defeat(source_id: String = "") -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	run_state.mark_defeat(source_id)

	_finish_run()

func _finish_run() -> void:
	if run_state == null:
		return

	if is_level_up_active:
		is_level_up_active = false
		current_level_up_options.clear()
		pending_level_ups = 0

	run_state.is_paused = true

	result_payload = _build_result_payload()

	run_state.final_money_reward = result_payload.final_money_reward

	GameEvents.emit_debug("[RunController] Run finalizada. result=%s coins=%s final_money=%s xp=%s kills=%s level=%s" % [
		result_payload.result_type,
		str(result_payload.run_coins_collected),
		str(result_payload.final_money_reward),
		str(result_payload.run_xp_gained),
		str(result_payload.enemies_killed),
		str(result_payload.level_reached)
	])

	GameEvents.run_finished.emit(result_payload)

	if finish_run_pauses_tree:
		get_tree().paused = true

func _build_result_payload() -> RunResultPayload:
	var payload: RunResultPayload = RunResultPayload.new()

	var victory_multiplier: float = 1.0
	var victory_bonus: int = 0

	if map_definition != null:
		victory_multiplier = map_definition.victory_multiplier
		victory_bonus = map_definition.victory_bonus

	payload.result_type = run_state.result_type
	payload.victory = run_state.is_victory
	payload.defeat = run_state.is_defeat

	payload.queen_id = run_state.queen_id
	payload.map_id = run_state.map_id

	payload.elapsed_seconds = run_state.elapsed_seconds
	payload.survived_seconds = min(run_state.elapsed_seconds, run_state.map_duration_seconds)
	payload.map_duration_seconds = run_state.map_duration_seconds

	payload.run_coins_collected = run_state.run_coins_collected
	payload.victory_multiplier = victory_multiplier
	payload.victory_bonus = victory_bonus

	payload.final_money_reward = RewardResolver.calculate_final_money_reward(
		run_state.is_victory,
		run_state.run_coins_collected,
		victory_multiplier,
		victory_bonus
	)

	payload.run_xp_gained = run_state.run_xp_gained
	payload.enemies_killed = run_state.enemies_killed
	payload.level_reached = run_state.level_reached

	payload.damage_dealt = run_state.damage_dealt
	payload.damage_taken = run_state.damage_taken
	payload.death_cause = run_state.death_cause

	return payload

func _start_next_level_up() -> void:
	if run_state == null:
		return

	if run_state.is_finished:
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

	if run_state != null and run_state.is_finished:
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
