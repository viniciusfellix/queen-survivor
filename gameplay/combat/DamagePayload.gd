## Objeto runtime que carrega informações de um dano sendo aplicado.
##
## Responsabilidades:
## - transportar dano bruto simples ou componentes de dano;
## - identificar a fonte do dano;
## - informar se o dano pode ser reduzido por defesa;
## - servir como contrato entre hitboxes, hurtboxes, receivers e DamageResolver.
##
## Importante:
## DamagePayload não calcula dano sozinho. Ele apenas transporta os dados.
extends RefCounted
class_name DamagePayload

var raw_damage: int = 0

var damage_type: String = DamageTypes.PHYSICAL

var damage_components: Array[DamageComponentDefinition] = []

var source_node: Node = null

var source_id: String = ""

var source_display_name: String = ""

var can_be_reduced_by_defense: bool = true

## Inicializa o payload com dano simples e informações de fonte.
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

## Define componentes de dano compostos, duplicando o array recebido.
func set_components(p_damage_components: Array[DamageComponentDefinition]) -> void:
	damage_components = p_damage_components.duplicate()

## Informa se o payload usa componentes de dano em vez de dano simples.
func has_components() -> bool:
	return not damage_components.is_empty()

## Soma o dano bruto total considerando componentes válidos ou fallback simples.
func get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return raw_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

## Verifica se o payload possui dano e tipo/componentes válidos.
func is_valid_payload() -> bool:
	if has_components():
		return get_total_raw_damage() > 0

	return raw_damage > 0 and DamageTypes.is_valid_type(damage_type)
