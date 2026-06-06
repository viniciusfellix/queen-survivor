## Event bus global do projeto.
##
## Responsabilidades:
## - centralizar signals globais entre sistemas desacoplados;
## - permitir comunicação entre gameplay, UI, save, feedbacks e ferramentas técnicas;
## - evitar dependências diretas entre sistemas que não precisam conhecer um ao outro.
##
## Importante:
## Este arquivo declara signals, mas normalmente não os emite diretamente.
## Por isso o warning `unused_signal` é ignorado intencionalmente.
extends Node

@warning_ignore_start("unused_signal")

## Emitido quando a Gaia/player recebe dano.
##
## Usado por HUD, feedback visual, floating text e sistemas técnicos.
signal player_damaged(
	raw_damage: int,
	final_damage: int,
	current_hp: int,
	max_hp: int,
	source_id: String
)

## Emitido quando a Gaia/player morre.
signal player_died(source_id: String)

## Emitido quando um inimigo recebe dano.
##
## Pode ser usado por feedback visual, logs, efeitos ou estatísticas.
signal enemy_damaged(
	enemy_id: String,
	raw_damage: int,
	final_damage: int,
	current_hp: int,
	max_hp: int,
	source_id: String
)

## Emitido quando um inimigo morre.
##
## Carrega dados necessários para:
## - XP direta;
## - contador de kills;
## - tentativa de drop de moeda;
## - feedbacks;
## - estatísticas.
signal enemy_died(
	enemy_id: String,
	source_id: String,
	xp_reward: int,
	global_position: Vector2,
	coin_drop_chance: float,
	coin_drop_value: int
)

## Emitido quando a XP da run muda.
##
## Também carrega informações de level atual e progresso para o próximo level.
signal run_xp_changed(
	run_xp_gained: int,
	current_level: int,
	current_level_xp: int,
	xp_required_for_next_level: int
)

## Emitido quando o contador de inimigos mortos aumenta.
signal run_enemy_killed(enemy_id: String, enemies_killed: int)

## Emitido quando uma moeda física é coletada.
signal run_coin_collected(value: int, global_position: Vector2)

## Emitido quando o saldo de moedas da run muda.
##
## `run_coins_collected`: total coletado na run.
## `run_coins_available`: saldo disponível para sistemas como mercador futuro.
signal run_coins_changed(
	run_coins_collected: int,
	run_coins_available: int
)

## Emitido quando o level-up começa e opções são apresentadas.
signal run_level_up_started(current_level: int, options: Array)

## Emitido quando o jogador seleciona uma opção de upgrade.
signal run_level_up_option_selected(upgrade: UpgradeDefinition)

## Emitido quando o level-up termina e a run pode continuar.
signal run_level_up_completed(
	current_level: int,
	selected_upgrade_id: String
)

## Emitido durante atualização do timer da run.
signal run_timer_changed(
	elapsed_seconds: float,
	remaining_seconds: float,
	duration_seconds: float
)

## Emitido quando a run termina em vitória ou derrota.
##
## O payload carrega todos os dados calculados para resultado e save.
signal run_finished(result_payload: RunResultPayload)

## Emitido quando o cooldown de uma arma muda.
##
## Usado pelo HUD para exibir barra/progresso de recarga.
signal weapon_cooldown_changed(
	weapon_id: String,
	cooldown_timer: float,
	cooldown_seconds: float,
	progress_ratio: float
)

## Emitido quando uma animação Spine relevante muda.
##
## Usado principalmente pelo DebugOverlay e ferramentas técnicas.
signal spine_animation_changed(animation_name: String)

## Emitido quando o save em memória foi atualizado.
signal save_updated(save_data: SaveData)

## Emitido após tentativa de persistir resultado da run no save.
##
## Diferente de `save_updated`, este signal informa se o resultado daquela
## run específica foi salvo com sucesso em disco.
signal run_result_persisted(
	result_payload: RunResultPayload,
	save_data: SaveData,
	succeeded: bool
)

@warning_ignore_restore("unused_signal")
