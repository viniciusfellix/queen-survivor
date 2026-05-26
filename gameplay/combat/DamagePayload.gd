## Objeto de transporte de uma tentativa de dano.
##
## Um payload registra:
## - dano fallback simples;
## - componentes de dano composto;
## - fonte que produziu o ataque;
## - possibilidade de redução por defesa.
##
## O payload não calcula resultado. Esse trabalho pertence ao `DamageResolver`.
extends RefCounted
class_name DamagePayload

## Dano bruto fallback para ataques simples com um único tipo.
var raw_damage: int = 0

## Tipo associado ao dano fallback.
var damage_type: String = DamageTypes.PHYSICAL

## Componentes de dano utilizados por ataques compostos.
##
## Exemplo atual: a arma inicial da Gaia combina físico e mágico.
var damage_components: Array[DamageComponentDefinition] = []

## Node runtime que originou o ataque.
var source_node: Node = null

## ID técnico da fonte do ataque.
var source_id: String = ""

## Nome ou ID apresentável da fonte, previsto para feedback e resultados.
var source_display_name: String = ""

## Define se defesa percentual pode reduzir este payload.
##
## Dano verdadeiro pode alterar este valor para `false`.
var can_be_reduced_by_defense: bool = true

## Inicializa um payload simples ou a base de um payload composto.
func _init(
	p_raw_damage: int = 0,
	p_damage_type: String = DamageTypes.PHYSICAL,
	p_source_node: Node = null,
	p_source_id: String = "",
	p_source_display_name: String = ""
) -> void:
	raw_damage = p_raw_damage
	damage_type = p_damage_type
	source_node = p_source_node
	source_id = p_source_id
	source_display_name = p_source_display_name

## Define os componentes de dano que substituirão o fallback simples.
func set_components(p_damage_components: Array[DamageComponentDefinition]) -> void:
	damage_components = p_damage_components.duplicate()

## Informa se o payload utiliza dano composto.
func has_components() -> bool:
	return not damage_components.is_empty()

## Soma o dano bruto válido de todos os componentes.
##
## Quando não existem componentes, retorna o valor fallback.
func get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return raw_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

## Valida se o payload possui dano aplicável.
##
## Em payloads simples, além de dano positivo, exige tipo cadastrado.
func is_valid_payload() -> bool:
	if has_components():
		return get_total_raw_damage() > 0

	return raw_damage > 0 and DamageTypes.is_valid_type(damage_type)
