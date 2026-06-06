## Estado temporário da run atual.
##
## Responsabilidades:
## - armazenar tempo, mapa e Queen da run;
## - controlar pausa, encerramento e resultado;
## - armazenar XP, level, moedas, kills e estatísticas básicas;
## - bloquear alterações quando a run está encerrando/finalizada;
## - calcular progresso de XP e tempo.
##
## Importante:
## Este resource não é save permanente.
## Ao final da run, seus dados são convertidos em RunResultPayload.
extends Resource
class_name RunState

## ID do mapa atual.
var map_id: String = ""

## ID da Queen atual.
var queen_id: String = "gaia"

## Tempo decorrido da run.
var elapsed_seconds: float = 0.0

## Duração total configurada do mapa.
var map_duration_seconds: float = 600.0

## Indica se a run está pausada.
var is_paused: bool = false

## Estado intermediário de encerramento.
##
## Bloqueia gameplay antes do resultado final ser mostrado/persistido.
var is_ending: bool = false

## Indica vitória.
var is_victory: bool = false

## Indica derrota.
var is_defeat: bool = false

## Indica que a run foi finalizada formalmente.
var is_finished: bool = false

## Tipo final de resultado.
##
## Exemplo: "victory" ou "defeat".
var result_type: String = ""

## XP total obtida durante a run.
var run_xp_gained: int = 0

## Level atual da run.
var current_level: int = 1

## XP acumulada no level atual.
var current_level_xp: int = 0

## XP necessária para o próximo level.
var xp_required_for_next_level: int = 10

## Total de moedas coletadas fisicamente na run.
var run_coins_collected: int = 0

## Moedas gastas na run.
##
## Preparado para mercadores futuros.
var run_coins_spent: int = 0

## Inimigos mortos.
var enemies_killed: int = 0

## Maior level alcançado na run.
var level_reached: int = 1

## Dano total causado.
var damage_dealt: int = 0

## Dano total recebido.
var damage_taken: int = 0

## Causa da morte/derrota, se houver.
var death_cause: String = ""

## Recompensa final em dinheiro após vitória/derrota.
var final_money_reward: int = 0

## Configura estado inicial da run a partir do mapa.
func setup_from_map(map_definition: MapDefinition) -> void:
	if map_definition == null:
		return

	map_id = map_definition.id
	map_duration_seconds = map_definition.duration_seconds

## Adiciona XP direta à run.
##
## Retorna quantos levels foram ganhos com essa adição.
func add_xp(amount: int) -> int:
	if amount <= 0 or is_finished or is_ending:
		return 0

	run_xp_gained += amount
	current_level_xp += amount

	var levels_gained: int = _process_level_progression()

	return levels_gained

## Adiciona moedas coletadas.
func add_coins(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	run_coins_collected += amount

## Incrementa contador de inimigos mortos.
func add_enemy_kill() -> void:
	if is_finished or is_ending:
		return

	enemies_killed += 1

## Registra dano causado.
func add_damage_dealt(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_dealt += amount

## Registra dano recebido.
func add_damage_taken(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_taken += amount

## Retorna moedas disponíveis na run.
##
## Futuramente útil para mercadores:
## coletadas - gastas.
func get_run_coins_available() -> int:
	return max(0, run_coins_collected - run_coins_spent)

## Retorna progresso percentual do level atual.
func get_xp_progress_ratio() -> float:
	if xp_required_for_next_level <= 0:
		return 0.0

	return clamp(
		float(current_level_xp) / float(xp_required_for_next_level),
		0.0,
		1.0
	)

## Retorna tempo restante da run.
func get_remaining_seconds() -> float:
	return max(0.0, map_duration_seconds - elapsed_seconds)

## Retorna progresso percentual do tempo do mapa.
func get_time_progress_ratio() -> float:
	if map_duration_seconds <= 0.0:
		return 0.0

	return clamp(
		elapsed_seconds / map_duration_seconds,
		0.0,
		1.0
	)

## Inicia encerramento da run.
##
## Esse estado bloqueia gameplay antes de marcar vitória/derrota final.
func begin_ending(p_death_cause: String = "") -> bool:
	if is_finished or is_ending:
		return false

	is_ending = true
	death_cause = p_death_cause

	return true

## Marca a run como vitória finalizada.
func mark_victory() -> void:
	if is_finished:
		return

	is_ending = false
	is_finished = true
	is_victory = true
	is_defeat = false
	result_type = "victory"

## Marca a run como derrota finalizada.
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

## Processa ganho de levels enquanto houver XP suficiente.
func _process_level_progression() -> int:
	var levels_gained: int = 0

	while current_level_xp >= xp_required_for_next_level:
		current_level_xp -= xp_required_for_next_level
		current_level += 1
		level_reached = current_level
		levels_gained += 1
		xp_required_for_next_level = _get_xp_required_for_level(current_level)

	return levels_gained

## Fórmula atual de XP necessária por level.
##
## Level 1 → 2: 10 XP.
## Depois aumenta 5 XP por level.
func _get_xp_required_for_level(level: int) -> int:
	return 10 + ((level - 1) * 5)
