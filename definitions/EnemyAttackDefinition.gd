## Resource de configuração de um ataque executado por inimigo.
##
## Responsabilidades:
## - identificar tecnicamente o ataque;
## - definir dano bruto e tipo de dano;
## - definir intervalo entre impactos;
## - definir delay de segurança após o spawn;
## - armazenar as áreas ofensivas utilizadas pela hitbox runtime.
##
## Este resource não movimenta inimigos e não aplica dano sozinho.
## A detecção física é executada por `EnemyAttackHitbox`.
extends Resource
class_name EnemyAttackDefinition

## ID técnico único do ataque.
##
## Exemplo:
## `enemy_attack_chaser_basic_contact`
@export var id: String = ""

@export_group("Damage")

## Dano bruto causado por um impacto válido.
@export var raw_damage: int = 1

## Tipo do dano enviado ao receiver.
@export var damage_type: String = DamageTypes.PHYSICAL

## Define se defesa percentual do player pode reduzir este dano.
##
## Ataques do tipo TRUE_DAMAGE ignoram defesa independentemente
## deste valor.
@export var can_be_reduced_by_defense: bool = true

@export_group("Timing")

## Intervalo mínimo entre dois impactos válidos do mesmo ataque
## contra o mesmo receiver.
@export var hit_interval_seconds: float = 1.0

## Tempo após criação do inimigo em que esta hitbox ainda não causa dano.
##
## Evita dano imediato quando uma instância nasce próxima da Queen.
@export var start_delay_seconds: float = 0.75

@export_group("Attack Areas")

## Formas ofensivas que representam fisicamente este ataque.
##
## Um ataque pode possuir mais de uma área no futuro.
@export var attack_areas: Array[AttackAreaDefinition] = []

## Verifica se o ataque possui configuração mínima utilizável.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and raw_damage > 0
		and DamageTypes.is_valid_type(damage_type)
		and hit_interval_seconds > 0.0
		and start_delay_seconds >= 0.0
		and has_valid_attack_areas()
	)

## Indica se existe ao menos uma área ofensiva válida.
func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

## Constrói o payload enviado ao receiver atingido.
##
## A resolução final de defesa continua sob responsabilidade
## do `PlayerController` e do `DamageResolver`.
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

	payload.can_be_reduced_by_defense = (
		can_be_reduced_by_defense
		and damage_type != DamageTypes.TRUE_DAMAGE
	)

	return payload

## Retorna um resumo textual das áreas configuradas para logs.
func get_areas_debug_summary() -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		summaries.append(attack_area.get_debug_summary())

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
