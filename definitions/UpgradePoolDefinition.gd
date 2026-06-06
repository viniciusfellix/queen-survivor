## Resource que define uma pool de upgrades disponíveis em uma run/mapa.
##
## Responsabilidades:
## - armazenar lista de upgrades possíveis;
## - definir quantas opções aparecem por level-up;
## - filtrar upgrades válidos;
## - respeitar limite de stacks por run;
## - fornecer resumo técnico.
##
## Este resource não sorteia sozinho a opção final.
## Ele fornece dados para serviços como LevelUpOptionService.
extends Resource
class_name UpgradePoolDefinition

## ID técnico único da pool.
@export var id: String = ""

## Chave de localização para nome da pool, se necessário.
@export var display_name_key: String = ""

## Quantidade de opções exibidas no level-up.
##
## Regra atual do protótipo: 3 opções.
## Futuramente pode chegar a 4 ou 5 por progressão global.
@export var option_count: int = 3

## Lista de upgrades disponíveis nesta pool.
@export var upgrades: Array[UpgradeDefinition] = []

## Se true, o sistema tenta evitar repetir imediatamente as opções anteriores.
@export var avoid_last_offered_options: bool = true

## Se true, permite repetir opções quando a pool válida estiver pequena.
@export var allow_repeat_when_valid_pool_is_small: bool = true

## Verifica se a pool possui configuração mínima válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and option_count > 0 and not upgrades.is_empty()

## Retorna upgrades válidos considerando stacks já escolhidos.
##
## `selected_counts` deve usar:
## - chave: upgrade.id;
## - valor: quantidade de vezes escolhida nesta run.
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

## Retorna resumo textual da pool para logs/debug.
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

## Verifica se um upgrade ainda pode aparecer com base no limite de stacks.
func _upgrade_has_stack_available(upgrade: UpgradeDefinition, selected_counts: Dictionary) -> bool:
	if upgrade == null:
		return false

	if upgrade.max_stack_in_run <= 0:
		return false

	var current_count: int = int(selected_counts.get(upgrade.id, 0))

	return current_count < upgrade.max_stack_in_run
