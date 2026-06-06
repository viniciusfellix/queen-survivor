## Serviço estático responsável por calcular recompensa final de dinheiro.
##
## Responsabilidades:
## - aplicar a fórmula oficial de vitória;
## - aplicar regra oficial de derrota;
## - proteger contra moedas negativas e bônus negativo.
##
## Fórmula oficial:
## Vitória: (moedas_coletadas × victory_multiplier) + victory_bonus
## Derrota: moedas_coletadas
extends RefCounted
class_name RewardResolver

## Calcula dinheiro final respeitando fórmulas oficiais de vitória e derrota.
static func calculate_final_money_reward(
	victory: bool,
	run_coins_collected: int,
	victory_multiplier: float,
	victory_bonus: int
) -> int:
	var safe_coins: int = max(0, run_coins_collected)

	if victory:
		var multiplied_value: float = float(safe_coins) * victory_multiplier
		return int(round(multiplied_value)) + max(0, victory_bonus)

	return safe_coins
