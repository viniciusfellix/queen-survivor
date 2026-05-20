extends Node2D
class_name DirectionalAttackHitbox

@export var hit_radius: float = 72.0
@export var lifetime_seconds: float = 0.12

# Fallback simples.
@export var raw_damage: int = 5
@export var damage_type: String = DamageTypes.PHYSICAL

# Modelo oficial.
@export var damage_components: Array[DamageComponentDefinition] = []

@export var source_id: String = "gaia_initial_weapon"

@export var enemy_group_name: String = "enemy"

@export var draw_debug_hitbox: bool = true
@export var debug_color: Color = Color(0.2, 0.75, 1.0, 0.35)
@export var debug_outline_color: Color = Color(0.2, 0.9, 1.0, 0.95)

var elapsed_seconds: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var source_node: Node = null

var already_hit_instance_ids: Dictionary = {}

func _ready() -> void:
	queue_redraw()
	_try_hit_enemies()

func _physics_process(delta: float) -> void:
	elapsed_seconds += delta

	_try_hit_enemies()

	if elapsed_seconds >= lifetime_seconds:
		queue_free()

func _draw() -> void:
	if not draw_debug_hitbox:
		return

	draw_circle(Vector2.ZERO, hit_radius, debug_color)
	draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 32, debug_outline_color, 2.0)

	var nose_position: Vector2 = attack_direction.normalized() * hit_radius
	draw_line(Vector2.ZERO, nose_position, debug_outline_color, 2.0)
	draw_circle(nose_position, 4.0, debug_outline_color)

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
	hit_radius = p_hit_radius
	lifetime_seconds = p_lifetime_seconds
	source_id = p_source_id
	damage_components = p_damage_components.duplicate()

	rotation = attack_direction.angle()

	queue_redraw()

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

		GameEvents.emit_debug("[DirectionalAttackHitbox] Inimigo atingido: %s raw_total=%s final=%s components=%s" % [
			enemy_node.name,
			str(payload.get_total_raw_damage()),
			str(final_damage_variant),
			str(_get_component_debug_string())
		])

func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(raw_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [component.damage_type, str(component.amount)])

	return ", ".join(parts)
