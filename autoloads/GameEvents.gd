## Event Bus global do gameplay.
##
## Este autoload desacopla sistemas que precisam reagir ao mesmo evento sem
## depender diretamente uns dos outros. Por exemplo:
## - PlayerController emite dano recebido;
## - HUD e feedbacks visuais escutam esse evento;
## - RunController acompanha mortes e progressão;
## - SaveManager reage ao encerramento da run.
##
## Os signals são declarados neste arquivo, mas emitidos e consumidos por
## outros domínios; por isso o warning local `unused_signal` é intencional.
extends Node

@warning_ignore_start("unused_signal")

## Emitido quando a Queen recebe dano válido.
##
## Consumidores atuais incluem HUD e feedback visual de dano.
signal player_damaged(
	raw_damage: int,
	final_damage: int,
	current_hp: int,
	max_hp: int,
	source_id: String
)

## Emitido quando a Queen morre.
##
## O `source_id` identifica o inimigo ou fonte responsável pela derrota.
signal player_died(source_id: String)

## Emitido quando um inimigo recebe dano válido.
##
## Permite que sistemas visuais ou técnicos acompanhem dano sem depender
## diretamente do script de implementação do inimigo.
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
## Além da identificação da morte, transporta XP e dados de drop utilizados
## pelo RunController e pelo DropController.
signal enemy_died(
	enemy_id: String,
	source_id: String,
	xp_reward: int,
	global_position: Vector2,
	coin_drop_chance: float,
	coin_drop_value: int
)

## Emitido quando a XP da run ou a progressão de level muda.
signal run_xp_changed(
	run_xp_gained: int,
	current_level: int,
	current_level_xp: int,
	xp_required_for_next_level: int
)

## Emitido quando a contagem total de inimigos derrotados na run muda.
signal run_enemy_killed(enemy_id: String, enemies_killed: int)

## Emitido quando uma moeda física é efetivamente coletada pelo player.
##
## A moeda só entra no saldo da run após este evento, nunca apenas ao dropar.
signal run_coin_collected(value: int, global_position: Vector2)

## Emitido após atualização do saldo de moedas da run.
signal run_coins_changed(
	run_coins_collected: int,
	run_coins_available: int
)

## Emitido quando um novo level-up inicia e suas opções são apresentadas.
signal run_level_up_started(current_level: int, options: Array)

## Emitido quando o jogador escolhe uma opção no painel de level-up.
signal run_level_up_option_selected(upgrade: UpgradeDefinition)

## Emitido após o upgrade escolhido ser aplicado com sucesso.
signal run_level_up_completed(
	current_level: int,
	selected_upgrade_id: String
)

## Emitido durante a run para atualizar informações de tempo na interface.
signal run_timer_changed(
	elapsed_seconds: float,
	remaining_seconds: float,
	duration_seconds: float
)

## Emitido quando a run chega ao resultado definitivo de vitória ou derrota.
##
## O SaveManager escuta este evento para aplicar a recompensa permanente.
signal run_finished(result_payload: RunResultPayload)

## Emitido pela arma ativa para atualizar cooldown e barra correspondente na HUD.
signal weapon_cooldown_changed(
	weapon_id: String,
	cooldown_timer: float,
	cooldown_seconds: float,
	progress_ratio: float
)

## Emitido quando a animação Spine publicada pela Queen muda.
##
## No protótipo atual, é utilizado principalmente por ferramentas de debug.
signal spine_animation_changed(animation_name: String)

## Emitido sempre que o save em memória é atualizado e persistido ou resetado.
signal save_updated(save_data: SaveData)

## Emitido especificamente após tentar persistir o resultado de uma run.
##
## Permite que o ResultPanel diferencie "resultado exibido" de
## "resultado salvo com sucesso".
signal run_result_persisted(
	result_payload: RunResultPayload,
	save_data: SaveData,
	succeeded: bool
)

@warning_ignore_restore("unused_signal")
