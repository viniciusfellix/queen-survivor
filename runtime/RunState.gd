## Estado runtime de uma run ativa.
##
## Este resource armazena exclusivamente dados temporários da partida atual:
## tempo, XP, moedas coletadas, progressão de level, estatísticas e resultado.
##
## Dados permanentes não pertencem a este resource.
## A persistência final ocorre posteriormente pelo SaveManager,
## utilizando o payload construído pelo RunController.
extends Resource
class_name RunState

## Identificador do mapa atualmente em execução.
var map_id: String = ""

## Identificador da Queen utilizada na run.
var queen_id: String = "gaia"

## Tempo já transcorrido desde o início da run.
var elapsed_seconds: float = 0.0

## Duração máxima configurada para o mapa atual.
var map_duration_seconds: float = 600.0

## Indica se a run está pausada, normalmente durante seleção de upgrade.
var is_paused: bool = false

## Estado intermediário do encerramento.
##
## Fica verdadeiro quando o gameplay já foi bloqueado, mas a run
## ainda aguarda animação ou delay antes de exibir o resultado final.
var is_ending: bool = false

## Indica se a run terminou em vitória.
var is_victory: bool = false

## Indica se a run terminou em derrota.
var is_defeat: bool = false

## Indica se o resultado final já foi consolidado.
var is_finished: bool = false

## Tipo textual do resultado final: `victory`, `defeat` ou vazio.
var result_type: String = ""

## Quantidade total de XP única obtida durante a run.
##
## Esta XP serve tanto para os level-ups internos quanto para
## o progresso permanente aplicado ao final da partida.
var run_xp_gained: int = 0

## Level atual atingido dentro da run.
var current_level: int = 1

## XP acumulada no level atual.
var current_level_xp: int = 0

## XP necessária para atingir o próximo level.
var xp_required_for_next_level: int = 10

## Total de moedas fisicamente coletadas durante a run.
##
## Moedas dropadas mas não coletadas não entram neste valor.
var run_coins_collected: int = 0

## Quantidade de moedas gastas dentro da run.
##
## Campo preparado para implementação futura de mercadores.
var run_coins_spent: int = 0

## Quantidade de inimigos derrotados durante a run.
var enemies_killed: int = 0

## Maior level alcançado na run.
var level_reached: int = 1

## Dano total causado aos inimigos durante a run.
var damage_dealt: int = 0

## Dano total efetivamente recebido pela Queen durante a run.
var damage_taken: int = 0

## Identificador da fonte que causou a derrota.
var death_cause: String = ""

## Recompensa monetária permanente calculada ao finalizar a run.
var final_money_reward: int = 0

## Inicializa dados dependentes do mapa selecionado.
##
## Recebe o resource do mapa e copia apenas informações
## necessárias ao estado runtime da partida.
func setup_from_map(map_definition: MapDefinition) -> void:
	if map_definition == null:
		return

	map_id = map_definition.id
	map_duration_seconds = map_definition.duration_seconds

## Adiciona XP à run e processa possíveis novos levels.
##
## Retorna quantos levels foram atingidos com esse ganho.
## O ganho é ignorado quando a run já terminou ou está encerrando.
func add_xp(amount: int) -> int:
	if amount <= 0 or is_finished or is_ending:
		return 0

	run_xp_gained += amount
	current_level_xp += amount

	var levels_gained: int = _process_level_progression()

	return levels_gained

## Adiciona moedas efetivamente coletadas ao saldo da run.
##
## Drops existentes no mapa não entram neste total
## enquanto não forem coletados pela personagem.
func add_coins(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	run_coins_collected += amount

## Registra uma nova eliminação realizada durante a run.
func add_enemy_kill() -> void:
	if is_finished or is_ending:
		return

	enemies_killed += 1

## Soma dano causado às estatísticas temporárias da run.
func add_damage_dealt(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_dealt += amount

## Soma dano recebido às estatísticas temporárias da run.
func add_damage_taken(amount: int) -> void:
	if amount <= 0 or is_finished or is_ending:
		return

	damage_taken += amount

## Retorna o saldo de moedas ainda disponível dentro da run.
##
## No protótipo atual, como não há mercador ativo,
## o valor normalmente corresponde às moedas coletadas.
func get_run_coins_available() -> int:
	return max(0, run_coins_collected - run_coins_spent)

## Retorna a proporção visual de progresso até o próximo level.
##
## O resultado permanece limitado entre `0.0` e `1.0`
## para uso seguro em barras de UI.
func get_xp_progress_ratio() -> float:
	if xp_required_for_next_level <= 0:
		return 0.0

	return clamp(
		float(current_level_xp) / float(xp_required_for_next_level),
		0.0,
		1.0
	)

## Retorna quantos segundos ainda restam antes do limite do mapa.
func get_remaining_seconds() -> float:
	return max(0.0, map_duration_seconds - elapsed_seconds)

## Retorna a proporção temporal já concluída da run.
##
## O resultado pode ser utilizado em barras, eventos ou debug.
func get_time_progress_ratio() -> float:
	if map_duration_seconds <= 0.0:
		return 0.0

	return clamp(
		elapsed_seconds / map_duration_seconds,
		0.0,
		1.0
	)

## Inicia o estado intermediário de encerramento da run.
##
## Retorna `true` apenas quando o encerramento começou nesta chamada.
## O RunController utiliza este estado para impedir novos eventos
## de gameplay durante o delay anterior à tela de resultado.
func begin_ending(p_death_cause: String = "") -> bool:
	if is_finished or is_ending:
		return false

	is_ending = true
	death_cause = p_death_cause

	return true

## Consolida a run como vitória.
##
## O cálculo da recompensa e a persistência são responsabilidades
## externas, executadas pelo fluxo de encerramento do RunController.
func mark_victory() -> void:
	if is_finished:
		return

	is_ending = false
	is_finished = true
	is_victory = true
	is_defeat = false
	result_type = "victory"

## Consolida a run como derrota.
##
## Quando uma causa válida for informada, ela substitui ou completa
## a causa eventualmente armazenada durante `begin_ending()`.
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

## Processa progressão de level enquanto existir XP suficiente.
##
## Um único ganho elevado de XP pode produzir mais de um level-up,
## por isso o processamento ocorre dentro de um loop.
func _process_level_progression() -> int:
	var levels_gained: int = 0

	while current_level_xp >= xp_required_for_next_level:
		current_level_xp -= xp_required_for_next_level
		current_level += 1
		level_reached = current_level
		levels_gained += 1
		xp_required_for_next_level = _get_xp_required_for_level(current_level)

	return levels_gained

## Calcula a XP necessária para avançar a partir de determinado level.
##
## Progressão atual do protótipo:
## - level 1 para 2: 10 XP;
## - a cada novo level, a exigência aumenta em 5 XP.
func _get_xp_required_for_level(level: int) -> int:
	return 10 + ((level - 1) * 5)
