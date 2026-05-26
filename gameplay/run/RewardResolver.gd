## Serviço puro responsável por calcular a recompensa monetária final da run.
##
## Regra oficial atual:
## - vitória: dinheiro_final = (moedas_coletadas × multiplicador) + bônus;
## - derrota: dinheiro_final = moedas_coletadas.
##
## Este serviço não altera save, não encerra run e não concede moedas.
## Ele apenas calcula o valor final a partir dos parâmetros recebidos.
extends RefCounted
class_name RewardResolver

## Calcula a quantidade de dinheiro permanente recebida ao final da run.
##
## Parâmetros:
## - `victory`: informa se o encerramento foi vitória;
## - `run_coins_collected`: moedas fisicamente coletadas na run;
## - `victory_multiplier`: multiplicador configurado no mapa;
## - `victory_bonus`: bônus fixo configurado no mapa.
##
## Moedas negativas e bônus negativos são impedidos de reduzir
## indevidamente a recompensa final.
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
