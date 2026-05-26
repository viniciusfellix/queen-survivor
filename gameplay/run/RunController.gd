## Controlador principal de uma run jogável.
##
## Responsabilidades:
## - inicializar o `RunState` com o mapa atual;
## - controlar tempo e condições de vitória/derrota;
## - receber eventos de morte, dano e coleta;
## - administrar XP, level-ups e aplicação transacional de upgrades;
## - construir o `RunResultPayload`;
## - emitir o encerramento da run para save e interfaces;
## - expor ferramentas técnicas de vitória/derrota forçada.
##
## Este controller coordena sistemas, mas não implementa diretamente:
## - combate da Queen;
## - comportamento dos inimigos;
## - criação visual de drops;
## - persistência permanente.
extends Node

## Estado mutável da run atual.
##
## Pode ser configurado pelo Inspector ou criado automaticamente ao iniciar.
@export var run_state: RunState

## Configuração do mapa executado nesta run.
##
## Define duração, recompensa de vitória, timeline de spawn e pool padrão.
@export var map_definition: MapDefinition

## Override opcional da pool de upgrades para cenas de teste.
##
## No fluxo normal, a pool deve vir de `MapDefinition.upgrade_pool`.
@export var upgrade_pool_definition: UpgradePoolDefinition

## Define se a SceneTree deve permanecer pausada após o resultado final.
@export var finish_run_pauses_tree: bool = true

## Delay visual entre a morte do player e a exibição da derrota.
@export var defeat_result_delay_seconds: float = 0.75

@export_group("Debug Tools")

## Permite que ferramentas do protótipo forcem vitória ou derrota.
##
## Deve permanecer desabilitado em cenas ou builds onde essa ação
## não seja desejada.
@export var allow_debug_force_finish: bool = false

## Quantidade de level-ups conquistados ainda aguardando escolha.
var pending_level_ups: int = 0

## Opções atualmente apresentadas no painel de level-up.
var current_level_up_options: Array[UpgradeDefinition] = []

## Indica se existe uma escolha de level-up ativa neste momento.
var is_level_up_active: bool = false

## Resultado final construído ao encerrar a run.
var result_payload: RunResultPayload = null

## Quantidade de vezes que cada upgrade foi escolhido na run atual.
var selected_upgrade_counts: Dictionary = {}

## IDs das opções oferecidas no level-up anterior.
##
## Utilizado para reduzir repetição imediata de cards quando a pool permitir.
var previous_upgrade_option_ids: Array[String] = []

## Prepara a run ao entrar na árvore:
## - mantém processamento durante pausas;
## - registra o controller no grupo global;
## - cria ou configura o estado da run;
## - resolve a pool de upgrades;
## - conecta eventos de gameplay.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run_controller")

	if run_state == null:
		run_state = RunState.new()

	if map_definition != null:
		run_state.setup_from_map(map_definition)

	_resolve_upgrade_pool()
	_connect_events()

	DeveloperAuditLogger.log_lifecycle(
		"Run iniciada. map=%s duration=%s" % [
			run_state.map_id,
			str(run_state.map_duration_seconds)
		],
		"RunController",
		{
			"map_id": run_state.map_id,
			"duration_seconds": run_state.map_duration_seconds,
			"queen_id": run_state.queen_id
		}
	)

## Atualiza o tempo da run enquanto o gameplay estiver ativo.
##
## Durante pause, encerramento intermediário ou resultado final,
## o tempo deixa de avançar.
##
## Quando o tempo alcança a duração do mapa, consolida vitória.
func _process(delta: float) -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	if run_state.is_paused or run_state.is_ending or run_state.is_victory or run_state.is_defeat:
		return

	run_state.elapsed_seconds += delta

	GameEvents.run_timer_changed.emit(
		run_state.elapsed_seconds,
		run_state.get_remaining_seconds(),
		run_state.map_duration_seconds
	)

	if run_state.elapsed_seconds >= run_state.map_duration_seconds:
		_finish_victory()

## Retorna o estado mutável da run atual.
##
## Utilizado por `RunQuery`, HUD e ferramentas técnicas.
func get_run_state() -> RunState:
	return run_state

## Retorna a definição do mapa executado nesta run.
func get_map_definition() -> MapDefinition:
	return map_definition

## Retorna a pool de upgrades atualmente utilizada pela run.
func get_upgrade_pool_definition() -> UpgradePoolDefinition:
	return upgrade_pool_definition

## Retorna o payload final após vitória ou derrota ser consolidada.
func get_result_payload() -> RunResultPayload:
	return result_payload

## Retorna informações técnicas da run para overlay e ferramentas de debug.
##
## Este método não representa contrato definitivo de UI comercial;
## sua finalidade é apoiar testes do protótipo.
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
		"is_ending": run_state.is_ending,
		"is_level_up_active": is_level_up_active,
		"pending_level_ups": pending_level_ups,
		"upgrade_pool_id": _get_upgrade_pool_id(),
		"selected_upgrade_counts": selected_upgrade_counts,
		"previous_upgrade_option_ids": previous_upgrade_option_ids,
		"is_finished": run_state.is_finished,
		"is_victory": run_state.is_victory,
		"is_defeat": run_state.is_defeat,
		"result_type": run_state.result_type,
		"final_money_reward": run_state.final_money_reward,
		"death_cause": run_state.death_cause
	}

## Conecta os sinais globais que alimentam estatísticas e fluxo da run.
##
## Emissores principais:
## - `EnemyBase`: dano recebido e morte do inimigo;
## - `CoinDrop`: moeda coletada;
## - `PlayerController`: dano recebido e morte do player;
## - `LevelUpPanel`: upgrade escolhido.
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

## Processa a morte válida de um inimigo durante a run.
##
## Fluxo:
## - incrementa abates;
## - adiciona XP direta;
## - acumula level-ups pendentes;
## - emite atualizações para HUD;
## - inicia a próxima escolha de upgrade quando necessário.
##
## O drop físico da moeda é tratado separadamente pelo `DropController`,
## que também escuta o evento `enemy_died`.
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

	if run_state.is_finished or run_state.is_ending or run_state.is_victory or run_state.is_defeat:
		return

	run_state.add_enemy_kill()

	var levels_gained: int = run_state.add_xp(xp_reward)

	if levels_gained > 0:
		pending_level_ups += levels_gained

	GameEvents.run_enemy_killed.emit(
		enemy_id,
		run_state.enemies_killed
	)

	GameEvents.run_xp_changed.emit(
		run_state.run_xp_gained,
		run_state.current_level,
		run_state.current_level_xp,
		run_state.xp_required_for_next_level
	)

	if levels_gained > 0:
		DeveloperAuditLogger.log_upgrade(
			"Nível alcançado: level=%s levels_gained=%s run_xp=%s xp=%s/%s pending_level_ups=%s" % [
				str(run_state.current_level),
				str(levels_gained),
				str(run_state.run_xp_gained),
				str(run_state.current_level_xp),
				str(run_state.xp_required_for_next_level),
				str(pending_level_ups)
			],
			"RunController",
			{
				"level": run_state.current_level,
				"levels_gained": levels_gained,
				"run_xp": run_state.run_xp_gained,
				"current_level_xp": run_state.current_level_xp,
				"xp_required": run_state.xp_required_for_next_level,
				"pending_level_ups": pending_level_ups,
				"enemy_id": enemy_id,
				"source_id": source_id,
				"enemy_position": enemy_global_position
			}
		)

	if pending_level_ups > 0 and not is_level_up_active:
		_start_next_level_up()

## Processa uma moeda física efetivamente coletada pelo player.
##
## Apenas moedas coletadas antes do encerramento entram no saldo da run.
## Moedas apenas dropadas ou ainda magnetizadas não geram recompensa.
func _on_run_coin_collected(value: int, coin_global_position: Vector2) -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	if value <= 0:
		return

	run_state.add_coins(value)

	GameEvents.run_coins_changed.emit(
		run_state.run_coins_collected,
		run_state.get_run_coins_available()
	)

	DeveloperAuditLogger.log_spawn(
		"Saldo de moedas atualizado: value=%s pos=%s total=%s available=%s" % [
			str(value),
			str(coin_global_position),
			str(run_state.run_coins_collected),
			str(run_state.get_run_coins_available())
		],
		"RunController",
		{
			"value": value,
			"position": coin_global_position,
			"total": run_state.run_coins_collected,
			"available": run_state.get_run_coins_available()
		}
	)

## Registra nas estatísticas da run o dano efetivamente recebido pelo player.
func _on_player_damaged(
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	run_state.add_damage_taken(final_damage)

## Registra nas estatísticas da run o dano efetivamente causado a inimigos.
func _on_enemy_damaged(
	_enemy_id: String,
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	run_state.add_damage_dealt(final_damage)

## Inicia o fluxo de derrota quando o player morre.
##
## O gameplay é bloqueado imediatamente por `begin_ending()`, evitando
## novos danos, moedas ou ações durante o delay visual de morte.
## Após o delay configurado, a derrota é consolidada.
func _on_player_died(source_id: String) -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	if not run_state.begin_ending(source_id):
		return

	DeveloperAuditLogger.log_lifecycle(
		"Gameplay bloqueada para encerramento da run. source=%s" % source_id,
		"RunController",
		{
			"source_id": source_id
		}
	)

	DeveloperAuditLogger.log_lifecycle(
		"Derrota agendada. source=%s delay=%s" % [
			source_id,
			str(defeat_result_delay_seconds)
		],
		"RunController",
		{
			"source_id": source_id,
			"delay_seconds": defeat_result_delay_seconds
		}
	)

	if defeat_result_delay_seconds <= 0.0:
		_finish_defeat(source_id)
		return

	var defeat_timer: SceneTreeTimer = get_tree().create_timer(defeat_result_delay_seconds)

	defeat_timer.timeout.connect(func() -> void:
		_finish_defeat(source_id)
	)

## Consolida vitória quando o tempo do mapa chega ao fim
## ou quando uma ferramenta técnica força esse resultado.
func _finish_victory() -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	run_state.elapsed_seconds = run_state.map_duration_seconds
	run_state.mark_victory()

	_finish_run()

## Consolida derrota após a morte do player ou por ferramenta técnica.
func _finish_defeat(source_id: String = "") -> void:
	if run_state == null:
		return

	if run_state.is_finished:
		return

	run_state.mark_defeat(source_id)

	_finish_run()

## Finaliza o fluxo comum de vitória ou derrota.
##
## Fluxo:
## - encerra qualquer level-up pendente;
## - pausa logicamente a run;
## - constrói o payload final;
## - registra o dinheiro obtido;
## - emite `GameEvents.run_finished`, consumido por save e UI;
## - opcionalmente pausa toda a SceneTree.
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

	DeveloperAuditLogger.log_lifecycle(
		"Run finalizada. result=%s coins=%s final_money=%s xp=%s kills=%s level=%s" % [
			result_payload.result_type,
			str(result_payload.run_coins_collected),
			str(result_payload.final_money_reward),
			str(result_payload.run_xp_gained),
			str(result_payload.enemies_killed),
			str(result_payload.level_reached)
		],
		"RunController",
		{
			"result_type": result_payload.result_type,
			"coins": result_payload.run_coins_collected,
			"final_money": result_payload.final_money_reward,
			"xp": result_payload.run_xp_gained,
			"kills": result_payload.enemies_killed,
			"level": result_payload.level_reached
		}
	)

	GameEvents.run_finished.emit(result_payload)

	if finish_run_pauses_tree:
		get_tree().paused = true

## Constrói o payload imutável por convenção utilizado no resultado e save.
##
## Regra monetária:
## - derrota: entrega somente moedas coletadas;
## - vitória: utiliza o multiplicador e bônus configurados no mapa.
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

## Inicia a próxima escolha pendente de level-up.
##
## A run e a árvore são pausadas enquanto o painel aguarda seleção.
## Caso a pool não possua opções válidas, o level-up é consumido
## sem escolha para evitar travar a execução.
func _start_next_level_up() -> void:
	if run_state == null:
		return

	if run_state.is_finished or run_state.is_ending:
		return

	if pending_level_ups <= 0:
		return

	is_level_up_active = true
	run_state.is_paused = true
	get_tree().paused = true

	current_level_up_options = _generate_level_up_options()

	if current_level_up_options.is_empty():
		DeveloperAuditLogger.log_upgrade(
			"Level-up sem opções válidas. Consumindo level-up pendente.",
			"RunController",
			{
				"level": run_state.current_level,
				"pool_id": _get_upgrade_pool_id(),
				"pending_level_ups": pending_level_ups
			}
		)

		_complete_level_up_without_option()
		return

	previous_upgrade_option_ids = _get_option_id_array(current_level_up_options)

	DeveloperAuditLogger.log_upgrade(
		"Level-up iniciado: level=%s pool=%s options=%s selected_counts=%s" % [
			str(run_state.current_level),
			_get_upgrade_pool_id(),
			_get_option_ids(current_level_up_options),
			str(selected_upgrade_counts)
		],
		"RunController",
		{
			"level": run_state.current_level,
			"pool_id": _get_upgrade_pool_id(),
			"option_ids": previous_upgrade_option_ids.duplicate(),
			"selected_counts": selected_upgrade_counts.duplicate(true),
			"pending_level_ups": pending_level_ups
		}
	)

	GameEvents.run_level_up_started.emit(run_state.current_level, current_level_up_options)

## Recebe a opção escolhida pelo painel de level-up.
##
## O upgrade é aplicado de forma transacional:
## - primeiro o efeito deve ser aceito pelo player ou arma;
## - somente depois o stack é registrado e a escolha consumida.
##
## Caso a aplicação falhe, o level-up permanece aberto para evitar
## consumir uma escolha que não produziu efeito.
func _on_level_up_option_selected(upgrade: UpgradeDefinition) -> void:
	if not is_level_up_active:
		return

	if run_state != null and (run_state.is_finished or run_state.is_ending):
		return

	if upgrade == null or not upgrade.is_valid_definition():
		push_warning("[RunController] Upgrade inválido selecionado.")
		return

	var applied_successfully: bool = _apply_upgrade(upgrade)

	if not applied_successfully:
		push_warning("[RunController] Level-up mantido aberto porque o upgrade não pôde ser aplicado: %s" % upgrade.id)
		return

	_register_selected_upgrade(upgrade)

	pending_level_ups = max(0, pending_level_ups - 1)

	var selected_stack: int = get_selected_upgrade_count(upgrade.id)

	GameEvents.run_level_up_completed.emit(
		run_state.current_level,
		upgrade.id
	)

	DeveloperAuditLogger.log_upgrade(
		"Level-up concluído: upgrade=%s stack=%s pending=%s" % [
			upgrade.id,
			str(selected_stack),
			str(pending_level_ups)
		],
		"RunController",
		{
			"upgrade_id": upgrade.id,
			"selected_stack": selected_stack,
			"pending_level_ups": pending_level_ups,
			"level": run_state.current_level
		}
	)

	if pending_level_ups > 0:
		_start_next_level_up()
		return

	is_level_up_active = false
	current_level_up_options.clear()

	if run_state != null:
		run_state.is_paused = false

	get_tree().paused = false

## Encaminha o upgrade escolhido para o player atual.
##
## O player é responsável por aplicar melhorias próprias ou encaminhar
## melhorias de arma. O retorno booleano informa se houve efeito real.
func _apply_upgrade(upgrade: UpgradeDefinition) -> bool:
	var player: Node = _get_player()

	if player == null:
		push_warning("[RunController] Player não encontrado para aplicar upgrade: %s" % upgrade.id)
		return false

	if not player.has_method("apply_run_upgrade"):
		push_warning("[RunController] Player sem apply_run_upgrade: %s" % upgrade.id)
		return false

	var applied_variant: Variant = player.call("apply_run_upgrade", upgrade)

	if applied_variant is bool:
		return bool(applied_variant)

	push_warning("[RunController] apply_run_upgrade precisa retornar bool: %s" % upgrade.id)
	return false

## Localiza a Queen ativa por meio do grupo `player`.
func _get_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return null

	return players[0]

## Converte a lista de opções em texto legível para logs técnicos.
func _get_option_ids(options: Array[UpgradeDefinition]) -> String:
	var ids: Array[String] = []

	for option: UpgradeDefinition in options:
		if option == null:
			continue

		ids.append(option.id)

	return ", ".join(ids)

## Resolve qual pool de upgrades será utilizada nesta run.
##
## Prioridade:
## 1. override configurado diretamente na cena;
## 2. pool cadastrada no `MapDefinition`.
func _resolve_upgrade_pool() -> void:
	if upgrade_pool_definition != null:
		DeveloperAuditLogger.log_upgrade(
			"UpgradePool ativa por override da cena: %s" % upgrade_pool_definition.get_debug_summary(),
			"RunController",
			{
				"pool_id": upgrade_pool_definition.id,
				"source": "scene_override"
			}
		)
		return

	if map_definition == null:
		push_warning("[RunController] MapDefinition ausente. Não foi possível resolver UpgradePool.")
		return

	if map_definition.upgrade_pool == null:
		push_warning("[RunController] MapDefinition sem UpgradePool configurada: %s" % map_definition.id)
		return

	upgrade_pool_definition = map_definition.upgrade_pool

	DeveloperAuditLogger.log_upgrade(
		"UpgradePool carregada pelo MapDefinition: %s" % upgrade_pool_definition.get_debug_summary(),
		"RunController",
		{
			"pool_id": upgrade_pool_definition.id,
			"map_id": map_definition.id,
			"source": "map_definition"
		}
	)

## Solicita ao serviço de opções novos cards válidos para o level-up atual.
func _generate_level_up_options() -> Array[UpgradeDefinition]:
	if upgrade_pool_definition == null:
		return []

	return LevelUpOptionService.generate_from_pool(
		upgrade_pool_definition,
		selected_upgrade_counts,
		previous_upgrade_option_ids
	)

## Registra que determinado upgrade foi aplicado com sucesso nesta run.
func _register_selected_upgrade(upgrade: UpgradeDefinition) -> void:
	if upgrade == null:
		return

	var current_count: int = int(selected_upgrade_counts.get(upgrade.id, 0))
	selected_upgrade_counts[upgrade.id] = current_count + 1

## Finaliza um level-up que não possuía nenhuma opção válida disponível.
##
## Evita que a run permaneça pausada indefinidamente quando a pool
## estiver vazia ou todos os upgrades alcançarem seus limites.
func _complete_level_up_without_option() -> void:
	pending_level_ups = max(0, pending_level_ups - 1)

	if pending_level_ups > 0:
		_start_next_level_up()
		return

	is_level_up_active = false
	current_level_up_options.clear()

	if run_state != null:
		run_state.is_paused = false

	get_tree().paused = false

## Retorna o ID da pool ativa ou `none` quando nenhuma pool foi resolvida.
func _get_upgrade_pool_id() -> String:
	if upgrade_pool_definition == null:
		return "none"

	return upgrade_pool_definition.id

## Converte as opções atuais em uma lista de IDs utilizada para evitar repetição.
func _get_option_id_array(options: Array[UpgradeDefinition]) -> Array[String]:
	var ids: Array[String] = []

	for option: UpgradeDefinition in options:
		if option == null:
			continue

		ids.append(option.id)

	return ids

## Retorna quantas vezes um upgrade já foi escolhido na run atual.
func get_selected_upgrade_count(upgrade_id: String) -> int:
	if upgrade_id.strip_edges() == "":
		return 0

	return int(selected_upgrade_counts.get(upgrade_id, 0))

## Retorna o nível/stack que um upgrade atingirá caso seja escolhido agora.
##
## Utilizado pelo painel para exibir badges como `Nv. 2`.
func get_next_upgrade_level(upgrade_id: String) -> int:
	return get_selected_upgrade_count(upgrade_id) + 1

## Força vitória por meio das ferramentas técnicas do protótipo.
##
## Retorna `true` somente quando a ação é permitida e aplicada.
func debug_force_victory() -> bool:
	if not allow_debug_force_finish:
		DeveloperAuditLogger.log_audit(
			"Tentativa de forçar vitória ignorada. Ação desabilitada.",
			"RunController"
		)
		return false

	if run_state == null:
		return false

	if run_state.is_finished or run_state.is_ending:
		return false

	DeveloperAuditLogger.log_audit(
		"Vitória forçada pelo painel de teste.",
		"RunController"
	)
	_finish_victory()

	return true

## Força derrota por meio das ferramentas técnicas do protótipo.
##
## Utiliza a causa `debug_force_defeat` para deixar explícito no resultado
## que a derrota não veio de uma interação normal de gameplay.
func debug_force_defeat() -> bool:
	if not allow_debug_force_finish:
		DeveloperAuditLogger.log_audit(
			"Tentativa de forçar derrota ignorada. Ação desabilitada.",
			"RunController"
		)
		return false

	if run_state == null:
		return false

	if run_state.is_finished or run_state.is_ending:
		return false

	DeveloperAuditLogger.log_audit(
		"Derrota forçada pelo painel de teste.",
		"RunController"
	)
	run_state.begin_ending("debug_force_defeat")
	_finish_defeat("debug_force_defeat")

	return true
