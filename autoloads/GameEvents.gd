extends Node

signal debug_message(message: String)

signal player_move_direction_changed(direction: Vector2)
signal player_aim_direction_changed(direction: Vector2)
signal player_state_changed(previous_state: String, new_state: String)

signal player_damaged(raw_damage: int, final_damage: int, current_hp: int, max_hp: int, source_id: String)
signal player_died(source_id: String)

signal enemy_damaged(enemy_id: String, raw_damage: int, final_damage: int, current_hp: int, max_hp: int, source_id: String)
signal enemy_died(enemy_id: String, source_id: String, xp_reward: int, global_position: Vector2)

signal run_xp_changed(run_xp_gained: int, current_level: int, current_level_xp: int, xp_required_for_next_level: int)
signal run_enemy_killed(enemy_id: String, enemies_killed: int)

signal run_level_up_started(current_level: int, options: Array)
signal run_level_up_option_selected(upgrade: UpgradeDefinition)
signal run_level_up_completed(current_level: int, selected_upgrade_id: String)

signal spine_animation_requested(animation_name: String)
signal spine_animation_changed(animation_name: String)

signal save_loaded()
signal save_created()
signal save_saved()

func emit_debug(message: String) -> void:
	print("[Debug] %s" % message)
	debug_message.emit(message)
