## Serviço responsável por gerar as opções oferecidas em cada level-up.
##
## Responsabilidades:
## - receber uma pool de upgrades válida;
## - desconsiderar upgrades que atingiram limite de stack;
## - evitar repetir imediatamente as opções do level-up anterior;
## - completar a lista com opções repetidas quando a pool disponível
##   não for suficiente e essa regra estiver habilitada.
##
## Este serviço não aplica upgrades e não altera estado da run.
## Ele apenas retorna quais `UpgradeDefinition` devem ser exibidos.
extends RefCounted
class_name LevelUpOptionService

## Gera opções de level-up a partir de uma definição completa de pool.
##
## Parâmetros:
## - `upgrade_pool_definition`: resource contendo upgrades e regras da pool;
## - `selected_counts`: quantidade já escolhida de cada upgrade na run;
## - `previous_option_ids`: ids exibidos no level-up imediatamente anterior.
##
## Retorna uma lista de upgrades válidos para apresentação no painel.
static func generate_from_pool(
	upgrade_pool_definition: UpgradePoolDefinition,
	selected_counts: Dictionary = {},
	previous_option_ids: Array[String] = []
) -> Array[UpgradeDefinition]:
	if upgrade_pool_definition == null:
		return []

	if not upgrade_pool_definition.is_valid_definition():
		return []

	var valid_upgrades: Array[UpgradeDefinition] = upgrade_pool_definition.get_valid_upgrades(selected_counts)

	return _generate_from_valid_options(
		valid_upgrades,
		upgrade_pool_definition.option_count,
		previous_option_ids,
		upgrade_pool_definition.avoid_last_offered_options,
		upgrade_pool_definition.allow_repeat_when_valid_pool_is_small
	)

## Monta a seleção final de opções a partir dos upgrades já filtrados.
##
## Primeiro tenta utilizar upgrades que não apareceram na seleção anterior.
## Quando ainda faltarem opções e a regra permitir, completa a seleção
## utilizando qualquer upgrade válido ainda não escolhido nesta rodada.
static func _generate_from_valid_options(
	valid_upgrades: Array[UpgradeDefinition],
	option_count: int,
	previous_option_ids: Array[String],
	avoid_last_offered_options: bool,
	allow_repeat_when_valid_pool_is_small: bool
) -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []

	if valid_upgrades.is_empty():
		return result

	# Garante ao menos uma opção solicitada, sem ultrapassar
	# a quantidade real de upgrades válidos disponíveis.
	var safe_option_count: int = max(1, option_count)
	var max_count: int = min(safe_option_count, valid_upgrades.size())

	var preferred_options: Array[UpgradeDefinition] = []

	# Quando habilitado, prioriza upgrades que não apareceram
	# no level-up imediatamente anterior.
	if avoid_last_offered_options:
		for upgrade: UpgradeDefinition in valid_upgrades:
			if upgrade == null:
				continue

			if previous_option_ids.has(upgrade.id):
				continue

			preferred_options.append(upgrade)
	else:
		preferred_options = valid_upgrades.duplicate()

	# Embaralha a seleção preferencial para evitar ordem fixa nos cards.
	preferred_options.shuffle()

	for upgrade: UpgradeDefinition in preferred_options:
		if result.size() >= max_count:
			break

		if upgrade == null:
			continue

		if _result_has_upgrade(result, upgrade.id):
			continue

		result.append(upgrade)

	# Caso as opções novas não sejam suficientes, reutiliza upgrades
	# válidos da pool para preencher os cards restantes.
	if result.size() < max_count and allow_repeat_when_valid_pool_is_small:
		var fallback_options: Array[UpgradeDefinition] = valid_upgrades.duplicate()
		fallback_options.shuffle()

		for upgrade: UpgradeDefinition in fallback_options:
			if result.size() >= max_count:
				break

			if upgrade == null:
				continue

			if _result_has_upgrade(result, upgrade.id):
				continue

			result.append(upgrade)

	return result

## Informa se a seleção atual já contém um upgrade com determinado id.
##
## Evita que a mesma melhoria seja exibida duas vezes
## dentro do mesmo painel de level-up.
static func _result_has_upgrade(
	result: Array[UpgradeDefinition],
	upgrade_id: String
) -> bool:
	for upgrade: UpgradeDefinition in result:
		if upgrade == null:
			continue

		if upgrade.id == upgrade_id:
			return true

	return false
