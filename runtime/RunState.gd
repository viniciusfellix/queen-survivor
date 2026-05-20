extends Resource
class_name RunState

var elapsed_seconds: float = 0.0

var is_paused: bool = false
var is_victory: bool = false
var is_defeat: bool = false

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

func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0

	run_xp_gained += amount
	current_level_xp += amount

	var levels_gained: int = _process_level_progression()

	return levels_gained

func add_coins(amount: int) -> void:
	if amount <= 0:
		return

	run_coins_collected += amount

func add_enemy_kill() -> void:
	enemies_killed += 1

func get_run_coins_available() -> int:
	return max(0, run_coins_collected - run_coins_spent)

func get_xp_progress_ratio() -> float:
	if xp_required_for_next_level <= 0:
		return 0.0

	return clamp(float(current_level_xp) / float(xp_required_for_next_level), 0.0, 1.0)

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
	elapsed_seconds = 0.0
	is_paused = false
	is_victory = false
	is_defeat = false

	run_xp_gained = 0

	current_level = 1
	current_level_xp = 0
	xp_required_for_next_level = 10

	run_coins_collected = 0
	run_coins_spent = 0

	enemies_killed = 0
	level_reached = 1
