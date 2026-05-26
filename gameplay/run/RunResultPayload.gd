## Payload imutável por convenção utilizado ao finalizar uma run.
##
## O RunController preenche este objeto quando vitória ou derrota é consolidada.
## Depois disso:
## - GameEvents.run_finished transporta o payload;
## - SaveManager aplica seus valores ao progresso permanente;
## - ResultPanel exibe o resumo para o jogador.
extends RefCounted
class_name RunResultPayload

## Tipo textual do resultado: normalmente `victory` ou `defeat`.
var result_type: String = "unknown"

## Indica se a run terminou em vitória.
var victory: bool = false

## Indica se a run terminou em derrota.
var defeat: bool = false

## Queen utilizada durante a run.
var queen_id: String = ""

## Mapa executado durante a run.
var map_id: String = ""

## Tempo total processado pela run antes do resultado.
var elapsed_seconds: float = 0.0

## Tempo efetivamente sobrevivido pelo jogador.
var survived_seconds: float = 0.0

## Duração configurada para o mapa executado.
var map_duration_seconds: float = 0.0

## Quantidade de moedas fisicamente coletadas durante a run.
var run_coins_collected: int = 0

## Multiplicador monetário aplicado somente em vitória.
var victory_multiplier: float = 1.0

## Bônus monetário adicional aplicado somente em vitória.
var victory_bonus: int = 0

## Recompensa monetária final calculada pelo RunController.
var final_money_reward: int = 0

## XP única obtida durante a run e entregue ao progresso permanente.
var run_xp_gained: int = 0

## Quantidade de inimigos derrotados durante a execução.
var enemies_killed: int = 0

## Maior nível alcançado durante a run.
var level_reached: int = 1

## Soma do dano causado pelo player durante a run.
var damage_dealt: int = 0

## Soma do dano recebido pelo player durante a run.
var damage_taken: int = 0

## ID da fonte responsável pela derrota, quando aplicável.
var death_cause: String = ""

## Converte o resultado final para dicionário serializável.
##
## Esta representação é salva em `SaveData.last_run_summary` e pode ser
## utilizada por painéis técnicos ou telas futuras de histórico resumido.
func to_dictionary() -> Dictionary:
	return {
		"result_type": result_type,
		"victory": victory,
		"defeat": defeat,
		"queen_id": queen_id,
		"map_id": map_id,
		"elapsed_seconds": elapsed_seconds,
		"survived_seconds": survived_seconds,
		"map_duration_seconds": map_duration_seconds,
		"run_coins_collected": run_coins_collected,
		"victory_multiplier": victory_multiplier,
		"victory_bonus": victory_bonus,
		"final_money_reward": final_money_reward,
		"run_xp_gained": run_xp_gained,
		"enemies_killed": enemies_killed,
		"level_reached": level_reached,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"death_cause": death_cause
	}
