## Resource que define um ataque de inimigo.
##
## Responsabilidades:
## - configurar dano bruto;
## - configurar tipo de dano;
## - informar se o dano pode ser reduzido por defesa;
## - configurar tempo entre hits;
## - configurar delay inicial antes do primeiro hit;
## - armazenar as áreas ofensivas do ataque.
##
## Exemplo atual:
## - ataque corporal do Goblin básico.
##
## Importante:
## Este resource apenas descreve o ataque.
## Quem executa a detecção e aplica o dano é o EnemyAttackHitbox.
extends Resource
class_name EnemyAttackDefinition

## ID técnico único do ataque.
@export var id: String = ""

@export_group("Damage")

## Dano bruto base causado por este ataque.
@export var raw_damage: int = 1

## Tipo de dano aplicado.
##
## Deve ser um tipo válido de DamageTypes.
@export var damage_type: String = DamageTypes.PHYSICAL

## Define se o dano pode ser reduzido pela defesa do player.
##
## Mesmo que esteja true, dano TRUE_DAMAGE nunca deve ser reduzido.
@export var can_be_reduced_by_defense: bool = true

@export_group("Timing")

## Intervalo mínimo entre aplicações de dano enquanto o alvo permanece na área.
@export var hit_interval_seconds: float = 1.0

## Delay antes do ataque começar a causar dano após ser ativado.
##
## Útil para evitar dano instantâneo assim que o inimigo nasce ou encosta.
@export var start_delay_seconds: float = 0.75

@export_group("Attack Areas")

## Áreas ofensivas deste ataque.
##
## Cada AttackAreaDefinition descreve uma shape configurável.
@export var attack_areas: Array[AttackAreaDefinition] = []

## Verifica se a definição possui configuração mínima válida.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and raw_damage > 0
		and DamageTypes.is_valid_type(damage_type)
		and hit_interval_seconds > 0.0
		and start_delay_seconds >= 0.0
		and has_valid_attack_areas()
	)

## Informa se existe pelo menos uma área ofensiva válida.
func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

## Cria o DamagePayload usado pelo EnemyAttackHitbox.
##
## O payload leva:
## - dano bruto;
## - tipo de dano;
## - source_node;
## - source_id;
## - id deste ataque.
func build_damage_payload(
	source_node: Node,
	source_id: String
) -> DamagePayload:
	var payload: DamagePayload = DamagePayload.new(
		raw_damage,
		damage_type,
		source_node,
		source_id,
		id
	)

	## TRUE_DAMAGE nunca deve ser reduzido por defesa.
	payload.can_be_reduced_by_defense = (
		can_be_reduced_by_defense
		and damage_type != DamageTypes.TRUE_DAMAGE
	)

	return payload

## Retorna resumo textual das áreas ofensivas para logs/debug.
func get_areas_debug_summary() -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		summaries.append(attack_area.get_debug_summary())

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
