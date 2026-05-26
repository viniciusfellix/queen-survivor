## Resource que reúne upgrades disponíveis para uma run.
##
## No protótipo atual, a pool é associada ao mapa e define:
## - quantidade de cards exibidos por level-up;
## - lista de upgrades possíveis;
## - regras simples para evitar repetição imediata;
## - fallback quando poucas opções permanecem válidas.
extends Resource
class_name UpgradePoolDefinition

## ID técnico único da pool.
##
## Exemplo atual: `upgrade_pool_gaia_default`.
@export var id: String = ""

## Chave de localização opcional para nome da pool.
@export var display_name_key: String = ""

## Quantidade de opções exibidas a cada level-up.
##
## Regra oficial atual:
## - inicia com 3 opções;
## - futuramente upgrades globais poderão aumentar para 4 ou 5.
@export var option_count: int = 3

## Lista de cards que podem ser oferecidos por esta pool.
@export var upgrades: Array[UpgradeDefinition] = []

## Define se opções apresentadas no level-up anterior devem ser evitadas
## na geração seguinte, quando existirem alternativas válidas.
@export var avoid_last_offered_options: bool = true

## Permite reutilizar opções anteriores quando a quantidade de cards válidos
## restantes for pequena demais para preencher a seleção.
@export var allow_repeat_when_valid_pool_is_small: bool = true

## Verifica se a pool possui ID, quantidade de opções e upgrades cadastrados.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and option_count > 0 and not upgrades.is_empty()

## Retorna somente upgrades válidos e ainda disponíveis para stack nesta run.
##
## `selected_counts` contém quantas vezes cada upgrade já foi aplicado.
func get_valid_upgrades(selected_counts: Dictionary = {}) -> Array[UpgradeDefinition]:
	var valid_upgrades: Array[UpgradeDefinition] = []

	for upgrade: UpgradeDefinition in upgrades:
		if upgrade == null:
			continue

		if not upgrade.is_valid_definition():
			continue

		if not _upgrade_has_stack_available(upgrade, selected_counts):
			continue

		valid_upgrades.append(upgrade)

	return valid_upgrades

## Retorna texto compacto utilizado em logs técnicos da pool.
func get_debug_summary() -> String:
	var ids: Array[String] = []

	for upgrade: UpgradeDefinition in upgrades:
		if upgrade == null:
			continue

		ids.append(upgrade.id)

	return "%s options=%s upgrades=%s" % [
		id,
		str(option_count),
		", ".join(ids)
	]

## Informa se determinado upgrade ainda pode ser escolhido nesta run.
func _upgrade_has_stack_available(upgrade: UpgradeDefinition, selected_counts: Dictionary) -> bool:
	if upgrade == null:
		return false

	if upgrade.max_stack_in_run <= 0:
		return false

	var current_count: int = int(selected_counts.get(upgrade.id, 0))

	return current_count < upgrade.max_stack_in_run
