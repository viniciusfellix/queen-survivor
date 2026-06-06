extends Node

@warning_ignore_start("unused_signal")

signal player_damaged(
	raw_damage: int,
	final_damage: int,
	current_hp: int,
	max_hp: int,
	source_id: String
)

signal player_died(source_id: String)

signal enemy_damaged(
	enemy_id: String,
	raw_damage: int,
	final_damage: int,
	current_hp: int,
	max_hp: int,
	source_id: String
)

signal enemy_died(
	enemy_id: String,
	source_id: String,
	xp_reward: int,
	global_position: Vector2,
	coin_drop_chance: float,
	coin_drop_value: int
)

signal run_xp_changed(
	run_xp_gained: int,
	current_level: int,
	current_level_xp: int,
	xp_required_for_next_level: int
)

signal run_enemy_killed(enemy_id: String, enemies_killed: int)

signal run_coin_collected(value: int, global_position: Vector2)

signal run_coins_changed(
	run_coins_collected: int,
	run_coins_available: int
)

signal run_level_up_started(current_level: int, options: Array)

signal run_level_up_option_selected(upgrade: UpgradeDefinition)

signal run_level_up_completed(
	current_level: int,
	selected_upgrade_id: String
)

signal run_timer_changed(
	elapsed_seconds: float,
	remaining_seconds: float,
	duration_seconds: float
)

signal run_finished(result_payload: RunResultPayload)

signal weapon_cooldown_changed(
	weapon_id: String,
	cooldown_timer: float,
	cooldown_seconds: float,
	progress_ratio: float
)

signal spine_animation_changed(animation_name: String)

signal save_updated(save_data: SaveData)

signal run_result_persisted(
	result_payload: RunResultPayload,
	save_data: SaveData,
	succeeded: bool
)

@warning_ignore_restore("unused_signal")
