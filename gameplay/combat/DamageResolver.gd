## Serviço estático responsável por calcular dano final.
##
## Responsabilidades:
## - aplicar defesa no dano recebido pelo player;
## - calcular dano causado a inimigos;
## - processar componentes de dano separadamente;
## - aplicar fraquezas e resistências configuradas no EnemyDefinition;
## - gerar breakdown detalhado para logs e auditoria.
##
## Importante:
## Este arquivo concentra regra matemática de dano para evitar duplicação.
extends RefCounted
class_name DamageResolver

## Calcula dano recebido pelo player após defesa percentual e dano mínimo.
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

## Calcula dano total em inimigo usando base_damage sempre e componentes condicionais.
static func calculate_enemy_damage(payload: DamagePayload, enemy_definition: EnemyDefinition) -> Dictionary:
	var result: Dictionary = {
		"raw_total": 0,
		"final_total": 0,
		"breakdown": []
	}

	if payload == null or not payload.is_valid_payload():
		return result

	var breakdown: Array = result["breakdown"]

	if payload.raw_damage > 0:
		var base_result: Dictionary = _calculate_base_damage(payload)
		result["raw_total"] = int(result["raw_total"]) + int(base_result["raw_damage"])
		result["final_total"] = int(result["final_total"]) + int(base_result["final_damage"])
		breakdown.append(base_result)

	for component: DamageComponentDefinition in payload.damage_components:
		if component == null or not component.is_valid_component():
			continue

		var component_result: Dictionary = _calculate_conditional_component_damage(
			component,
			enemy_definition
		)

		result["raw_total"] = int(result["raw_total"]) + int(component_result["raw_damage"])
		result["final_total"] = int(result["final_total"]) + int(component_result["final_damage"])
		breakdown.append(component_result)

	result["breakdown"] = breakdown

	return result

## Calcula o dano base principal, sempre aplicado sem fraqueza/resistência.
static func _calculate_base_damage(payload: DamagePayload) -> Dictionary:
	var raw_damage: int = max(0, payload.raw_damage)
	var final_damage: int = raw_damage

	return {
		"component_role": "base",
		"damage_type": payload.damage_type,
		"raw_damage": raw_damage,
		"final_damage": final_damage,
		"multiplier": 1.0,
		"is_weak": false,
		"is_resistant": false,
		"applied": final_damage > 0,
		"reason": "base"
	}

## Calcula um componente adicional condicional contra fraquezas/resistências do inimigo.
static func _calculate_conditional_component_damage(
	component: DamageComponentDefinition,
	enemy_definition: EnemyDefinition
) -> Dictionary:
	var raw_damage: int = component.amount
	var final_damage: int = 0

	var is_weak: bool = false
	var is_resistant: bool = false
	var reason: String = "neutral"
	var applied: bool = false

	if enemy_definition != null:
		is_weak = enemy_definition.is_weak_to_damage_type(component.damage_type)
		is_resistant = enemy_definition.is_resistant_to_damage_type(component.damage_type)

	if component.affected_by_resistance and is_resistant:
		reason = "resistant"
	elif component.affected_by_weakness and is_weak:
		final_damage = raw_damage
		applied = final_damage > 0
		reason = "weakness"

	return {
		"component_role": "conditional",
		"damage_type": component.damage_type,
		"raw_damage": raw_damage,
		"final_damage": final_damage,
		"multiplier": 1.0 if applied else 0.0,
		"is_weak": is_weak,
		"is_resistant": is_resistant,
		"applied": applied,
		"reason": reason
	}
