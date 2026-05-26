## Serviço estático responsável por calcular resultados finais de dano.
##
## Existem dois fluxos atuais:
## - dano recebido pela Queen, reduzido por defesa percentual;
## - dano recebido por inimigos, calculado por componente,
##   considerando fraquezas e resistências.
extends RefCounted
class_name DamageResolver

## Calcula dano final recebido pela Queen.
##
## Regras atuais:
## - dano bruto inválido retorna zero;
## - dano não reduzível ignora defesa;
## - defesa é limitada entre 0% e 100%;
## - impactos válidos que atravessam defesa causam ao menos 1 ponto.
static func calculate_received_damage(
	raw_damage: int,
	defense_percent: float,
	can_be_reduced_by_defense: bool = true
) -> int:
	if raw_damage <= 0:
		return 0

	if not can_be_reduced_by_defense:
		return max(1, raw_damage)

	var safe_defense_percent: float = clamp(defense_percent, 0.0, 100.0)
	var reduced_damage: float = float(raw_damage) - (float(raw_damage) * safe_defense_percent * 0.01)
	var final_damage: int = int(round(reduced_damage))

	return max(1, final_damage)

## Calcula dano causado a um inimigo.
##
## Para ataques compostos, resolve cada componente separadamente,
## permitindo que físico e mágico reajam de formas diferentes
## às fraquezas e resistências do alvo.
##
## Retorna:
## - `raw_total`;
## - `final_total`;
## - `breakdown` detalhado por componente.
static func calculate_enemy_damage(payload: DamagePayload, enemy_definition: EnemyDefinition) -> Dictionary:
	var result: Dictionary = {
		"raw_total": 0,
		"final_total": 0,
		"breakdown": []
	}

	if payload == null or not payload.is_valid_payload():
		return result

	if payload.has_components():
		for component: DamageComponentDefinition in payload.damage_components:
			if component == null or not component.is_valid_component():
				continue

			var component_result: Dictionary = _calculate_component_damage(component, enemy_definition)

			result["raw_total"] = int(result["raw_total"]) + int(component_result["raw_damage"])
			result["final_total"] = int(result["final_total"]) + int(component_result["final_damage"])

			var breakdown: Array = result["breakdown"]
			breakdown.append(component_result)
			result["breakdown"] = breakdown

		return result

	var fallback_component: DamageComponentDefinition = DamageComponentDefinition.new()
	fallback_component.damage_type = payload.damage_type
	fallback_component.amount = payload.raw_damage
	fallback_component.affected_by_weakness = true
	fallback_component.affected_by_resistance = true

	var fallback_result: Dictionary = _calculate_component_damage(fallback_component, enemy_definition)

	result["raw_total"] = int(fallback_result["raw_damage"])
	result["final_total"] = int(fallback_result["final_damage"])
	result["breakdown"] = [fallback_result]

	return result

## Resolve um único componente de dano contra uma definition inimiga.
##
## Multiplicador inicial: `1.0`.
## Fraqueza acrescenta percentual configurado.
## Resistência reduz percentual configurado.
## O multiplicador nunca fica abaixo de zero.
static func _calculate_component_damage(component: DamageComponentDefinition, enemy_definition: EnemyDefinition) -> Dictionary:
	var raw_damage: int = component.amount
	var final_damage_float: float = float(raw_damage)

	var is_weak: bool = false
	var is_resistant: bool = false
	var multiplier: float = 1.0

	if enemy_definition != null:
		is_weak = enemy_definition.is_weak_to_damage_type(component.damage_type)
		is_resistant = enemy_definition.is_resistant_to_damage_type(component.damage_type)

		if component.affected_by_weakness and is_weak:
			multiplier += enemy_definition.weakness_bonus_percent * 0.01

		if component.affected_by_resistance and is_resistant:
			multiplier -= enemy_definition.resistance_reduction_percent * 0.01

	multiplier = max(0.0, multiplier)
	final_damage_float *= multiplier

	var final_damage: int = int(round(final_damage_float))

	if raw_damage > 0 and multiplier > 0.0:
		final_damage = max(1, final_damage)

	return {
		"damage_type": component.damage_type,
		"raw_damage": raw_damage,
		"final_damage": final_damage,
		"multiplier": multiplier,
		"is_weak": is_weak,
		"is_resistant": is_resistant
	}
