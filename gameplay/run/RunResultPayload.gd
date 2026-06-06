## Payload com o resultado final de uma run.
##
## Responsabilidades:
## - transportar dados calculados pelo RunController/RewardResolver;
## - alimentar ResultPanel;
## - alimentar SaveManager;
## - gerar Dictionary serializável para save/debug.
##
## Este objeto não calcula recompensa. Ele apenas carrega os dados finais.
extends RefCounted
class_name RunResultPayload

var result_type: String = "unknown"
var victory: bool = false
var defeat: bool = false
var queen_id: String = ""
var map_id: String = ""
var elapsed_seconds: float = 0.0
var survived_seconds: float = 0.0
var map_duration_seconds: float = 0.0
var run_coins_collected: int = 0
var victory_multiplier: float = 1.0
var victory_bonus: int = 0
var final_money_reward: int = 0
var run_xp_gained: int = 0
var enemies_killed: int = 0
var level_reached: int = 1
var damage_dealt: int = 0
var damage_taken: int = 0
var death_cause: String = ""

## Serializa os dados do resultado para save, debug ou UI.
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
