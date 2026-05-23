extends Resource
class_name RunState

var map_id: String = ""
var queen_id: String = "gaia"

var elapsed_seconds: float = 0.0
var map_duration_seconds: float = 600.0

var is_paused: bool = false

# Estado intermediário:
# true quando a run já encerrou gameplay, mas ainda aguarda animação/delay
# antes da exibição do resultado final.
var is_ending: bool = false

var is_victory: bool = false
var is_defeat: bool = false
var is_finished: bool = false

var result_type: String = ""

# XP única obtida durante a run.
var run_xp_gained: int = 0

# Level interno da run.
var current_level: int = 1
var current_level_xp: int = 0
var xp_required_for_next_level: int = 10

# Moeda da run.
# Moeda precisa ser coletada fisicamente.
var run_coins_collected: int = 0

# Previsto para mercador futuro.
var run_coins_spent: int = 0

var enemies_killed: int = 0
var level_reached: int = 1

var damage_dealt: int = 0
var damage_taken: int = 0
var death_cause: String = ""

var final_money_reward: int = 0

func setup_from_map(map_definition: MapDefinition) -> void:
	if map_definition == null:
		return

	map_id = map_definition.id
	map_duration_seconds = map_definition.duration_seconds

func add_xp(amount: int) -> int:
	if amount <= 0 or is_finished or is_ending:
		return 0

	run_xp_gained += amount
	current_level_xp += amount

	var levels_gained: int = _process_level_progression()

	return levels_gained

func add_coins(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	run_coins_collected += amount

func add_enemy_kill() -> void:
	if is_finished or is_ending:
		return

	enemies_killed += 1

func add_damage_dealt(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_dealt += amount

func add_damage_taken(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_taken += amount

func get_run_coins_available() -> int:
	return max(0, run_coins_collected - run_coins_spent)

func get_xp_progress_ratio() -> float:
	if xp_required_for_next_level <= 0:
		return 0.0

	return clamp(float(current_level_xp) / float(xp_required_for_next_level), 0.0, 1.0)

func get_remaining_seconds() -> float:
	return max(0.0, map_duration_seconds - elapsed_seconds)

func get_time_progress_ratio() -> float:
	if map_duration_seconds <= 0.0:
		return 0.0

	return clamp(elapsed_seconds / map_duration_seconds, 0.0, 1.0)

func begin_ending(p_death_cause: String = "") -> bool:
	if is_finished or is_ending:
		return false

	is_ending = true
	death_cause = p_death_cause

	return true

func mark_victory() -> void:
	if is_finished:
		return

	is_ending = false
	is_finished = true
	is_victory = true
	is_defeat = false
	result_type = "victory"

func mark_defeat(p_death_cause: String = "") -> void:
	if is_finished:
		return

	is_ending = false
	is_finished = true
	is_victory = false
	is_defeat = true
	result_type = "defeat"

	if p_death_cause.strip_edges() != "":
		death_cause = p_death_cause

func _process_level_progression() -> int:
	var levels_gained: int = 0

	while current_level_xp >= xp_required_for_next_level:
		current_level_xp -= xp_required_for_next_level
		current_level += 1
		level_reached = current_level
		levels_gained += 1
		xp_required_for_next_level = _get_xp_required_for_level(current_level)

	return levels_gained

func _get_xp_required_for_level(level: int) -> int:
	return 10 + ((level - 1) * 5)

func reset() -> void:
	map_id = ""
	queen_id = "gaia"

	elapsed_seconds = 0.0
	map_duration_seconds = 600.0

	is_paused = false
	is_ending = false
	is_victory = false
	is_defeat = false
	is_finished = false
	
	result_type = ""

	run_xp_gained = 0

	current_level = 1
	current_level_xp = 0
	xp_required_for_next_level = 10

	run_coins_collected = 0
	run_coins_spent = 0

	enemies_killed = 0
	level_reached = 1

	damage_dealt = 0
	damage_taken = 0
	death_cause = ""
	final_money_reward = 0
