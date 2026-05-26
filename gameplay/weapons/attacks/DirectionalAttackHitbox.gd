## Hitbox temporária criada por um disparo direcional.
##
## Responsabilidades:
## - armazenar snapshot do dano do ataque;
## - verificar inimigos dentro do raio;
## - impedir múltiplos impactos no mesmo inimigo por disparo;
## - construir `DamagePayload`;
## - desaparecer ao final de sua duração.
extends Node2D
class_name DirectionalAttackHitbox

## Raio atual da área de acerto.
@export var hit_radius: float = 72.0

## Tempo, em segundos, durante o qual esta hitbox permanece ativa.
@export var lifetime_seconds: float = 0.12

## Dano fallback utilizado quando não existem componentes.
@export var raw_damage: int = 5

## Tipo do dano fallback.
@export var damage_type: String = DamageTypes.PHYSICAL

## Componentes de dano aplicados por esta hitbox.
@export var damage_components: Array[DamageComponentDefinition] = []

## ID técnico da fonte responsável pelo ataque.
@export var source_id: String = "gaia_initial_weapon"

## Grupo onde os alvos atingíveis serão procurados.
@export var enemy_group_name: String = "enemy"

## Exibe visualmente o raio e a direção da hitbox.
@export var draw_debug_hitbox: bool = false

## Cor de preenchimento da hitbox técnica.
@export var debug_color: Color = Color(0.2, 0.75, 1.0, 0.35)

## Cor do contorno e direção da hitbox técnica.
@export var debug_outline_color: Color = Color(0.2, 0.9, 1.0, 0.95)

## Tempo transcorrido desde que esta hitbox foi configurada.
var elapsed_seconds: float = 0.0

## Direção normalizada do disparo que gerou esta hitbox.
var attack_direction: Vector2 = Vector2.RIGHT

## Node responsável por disparar o ataque.
var source_node: Node = null

## IDs de instâncias já atingidas por esta hitbox.
##
## Garante no máximo um impacto por inimigo em cada disparo.
var already_hit_instance_ids: Dictionary = {}

## Define se `setup()` já forneceu os dados necessários ao processamento.
var is_configured: bool = false

## Prepara desenho técnico e descarta a hitbox caso o gameplay já esteja bloqueado.
func _ready() -> void:
	queue_redraw()

	if RunQuery.is_gameplay_blocked(get_tree()):
		queue_free()

## Verifica impactos enquanto a hitbox estiver configurada e ativa.
func _physics_process(delta: float) -> void:
	if not is_configured:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		queue_free()
		return

	elapsed_seconds += delta

	_try_hit_enemies()

	if elapsed_seconds >= lifetime_seconds:
		queue_free()

## Desenha raio e orientação da hitbox quando o debug visual está ativo.
func _draw() -> void:
	if not draw_debug_hitbox:
		return

	draw_circle(Vector2.ZERO, hit_radius, debug_color)
	draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 32, debug_outline_color, 2.0)

	var nose_position: Vector2 = attack_direction.normalized() * hit_radius
	draw_line(Vector2.ZERO, nose_position, debug_outline_color, 2.0)
	draw_circle(nose_position, 4.0, debug_outline_color)

## Configura a hitbox com o snapshot de um disparo.
##
## Componentes são duplicados profundamente para preservar o valor
## do ataque mesmo que a arma receba upgrades durante a vida desta hitbox.
func setup(
	p_source_node: Node,
	p_direction: Vector2,
	p_raw_damage: int,
	p_damage_type: String,
	p_hit_radius: float,
	p_lifetime_seconds: float,
	p_source_id: String = "gaia_initial_weapon",
	p_damage_components: Array[DamageComponentDefinition] = []
) -> void:
	source_node = p_source_node

	if p_direction.length() > 0.001:
		attack_direction = p_direction.normalized()
	else:
		attack_direction = Vector2.RIGHT

	raw_damage = p_raw_damage
	damage_type = p_damage_type
	hit_radius = max(0.0, p_hit_radius)
	lifetime_seconds = max(0.01, p_lifetime_seconds)
	source_id = p_source_id

	damage_components.clear()

	for component: DamageComponentDefinition in p_damage_components:
		if component == null:
			continue

		var duplicated_component: DamageComponentDefinition = component.duplicate(true) as DamageComponentDefinition
		damage_components.append(duplicated_component)

	rotation = attack_direction.angle()
	elapsed_seconds = 0.0
	is_configured = true

	queue_redraw()

## Procura inimigos dentro da área e aplica dano uma única vez em cada alvo.
func _try_hit_enemies() -> void:
	if raw_damage <= 0 and damage_components.is_empty():
		return

	var enemies: Array[Node] = get_tree().get_nodes_in_group(enemy_group_name)

	for enemy: Node in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue

		if not enemy is Node2D:
			continue

		var enemy_node: Node2D = enemy as Node2D
		var instance_id: int = int(enemy_node.get_instance_id())

		if already_hit_instance_ids.has(instance_id):
			continue

		var distance_to_enemy: float = global_position.distance_to(enemy_node.global_position)

		if distance_to_enemy > hit_radius:
			continue

		if not enemy_node.has_method("receive_damage"):
			continue

		var payload: DamagePayload = DamagePayload.new(
			raw_damage,
			damage_type,
			source_node,
			source_id,
			source_id
		)

		if not damage_components.is_empty():
			payload.set_components(damage_components)

		var final_damage_variant: Variant = enemy_node.call("receive_damage", payload)

		already_hit_instance_ids[instance_id] = true

		DeveloperAuditLogger.log_combat(
			"Inimigo atingido: %s raw_total=%s final=%s components=%s" % [
				enemy_node.name,
				str(payload.get_total_raw_damage()),
				str(final_damage_variant),
				_get_component_debug_string()
			],
			"DirectionalAttackHitbox",
			{
				"enemy_name": enemy_node.name,
				"raw_total": payload.get_total_raw_damage(),
				"final_damage": final_damage_variant,
				"components": _get_component_debug_string(),
				"source_id": source_id
			}
		)

		if RunQuery.is_gameplay_blocked(get_tree()):
			return

## Retorna descrição compacta dos componentes aplicada nos logs técnicos.
func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(raw_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [component.damage_type, str(component.amount)])

	return ", ".join(parts)
