## Hitbox runtime de um ataque direcional.
##
## Responsabilidades:
## - funcionar como Area2D ofensiva temporária;
## - construir CollisionShape2D a partir das AttackAreaDefinition da arma;
## - detectar HurtboxComponent pertencentes a inimigos;
## - impedir múltiplos hits no mesmo receiver pela mesma instância;
## - construir DamagePayload;
## - enviar dano ao receiver;
## - desenhar a área ofensiva durante testes;
## - desaparecer ao fim do lifetime.
extends Area2D
class_name DirectionalAttackHitbox

@export_group("Lifetime")

@export var lifetime_seconds: float = 0.12

@export_group("Damage Fallback")

@export var raw_damage: int = 5
@export var damage_type: String = DamageTypes.PHYSICAL

@export_group("Damage Components")

@export var damage_components: Array[DamageComponentDefinition] = []

@export_group("Attack Areas")

@export var attack_areas: Array[AttackAreaDefinition] = []

## Multiplicador runtime aplicado às dimensões das áreas ofensivas.
@export var attack_area_scale_multiplier: float = 1.0

@export_group("Source")

@export var source_id: String = "gaia_initial_weapon"

@export_group("Collision Filter")

## Layer 4 = PlayerAttackHitbox.
@export_range(1, 32, 1) var attack_collision_layer_number: int = 4

## Layer 5 = EnemyHurtbox.
@export_range(1, 32, 1) var target_hurtbox_mask_number: int = 5

@export_group("Debug")

@export var draw_debug_hitbox: bool = false
@export var debug_color: Color = Color(0.2, 0.75, 1.0, 0.35)
@export var debug_outline_color: Color = Color(0.2, 0.9, 1.0, 0.95)

var elapsed_seconds: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var source_node: Node = null

var runtime_shape_nodes: Array[CollisionShape2D] = []
var already_hit_instance_ids: Dictionary = {}

var is_configured: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = false

	_configure_collision_filter()

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if RunQuery.is_gameplay_blocked(get_tree()):
		queue_free()
		return

	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_configured:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		queue_free()
		return

	elapsed_seconds += delta

	_process_current_overlaps()

	if elapsed_seconds >= lifetime_seconds:
		queue_free()

## Desenha a configuração ofensiva atual para balanceamento visual.
##
## A arma atual da Gaia utiliza RectangleShape2D.
## Shapes futuras continuam visíveis por Debug > Visible Collision Shapes,
## mesmo que ainda não tenham desenho customizado neste método.
func _draw() -> void:
	if not draw_debug_hitbox:
		return

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null or not attack_area.is_valid_definition():
			continue

		draw_set_transform(
			attack_area.local_offset,
			deg_to_rad(attack_area.local_rotation_degrees),
			Vector2.ONE
		)

		if attack_area.shape is CircleShape2D:
			var radius: float = attack_area.get_scaled_circle_radius(
				attack_area_scale_multiplier
			)

			draw_circle(Vector2.ZERO, radius, debug_color)
			draw_arc(
				Vector2.ZERO,
				radius,
				0.0,
				TAU,
				32,
				debug_outline_color,
				2.0
			)

		elif attack_area.shape is RectangleShape2D:
			var rectangle_size: Vector2 = attack_area.get_scaled_rectangle_size(
				attack_area_scale_multiplier
			)

			var rectangle: Rect2 = Rect2(
				-rectangle_size * 0.5,
				rectangle_size
			)

			draw_rect(rectangle, debug_color, true)
			draw_rect(rectangle, debug_outline_color, false, 2.0)

		draw_circle(Vector2.ZERO, 3.0, debug_outline_color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Configura esta hitbox no momento do disparo.
##
## A assinatura permanece compatível com o controller da Gaia já alterado
## para utilizar AttackAreaDefinition.
func setup(
	p_source_node: Node,
	p_direction: Vector2,
	p_raw_damage: int,
	p_damage_type: String,
	p_attack_areas: Array[AttackAreaDefinition],
	p_lifetime_seconds: float,
	p_source_id: String = "gaia_initial_weapon",
	p_damage_components: Array[DamageComponentDefinition] = [],
	p_attack_area_scale_multiplier: float = 1.0
) -> void:
	source_node = p_source_node

	if p_direction.length() > 0.001:
		attack_direction = p_direction.normalized()
	else:
		attack_direction = Vector2.RIGHT

	raw_damage = p_raw_damage
	damage_type = p_damage_type
	lifetime_seconds = max(0.01, p_lifetime_seconds)
	source_id = p_source_id
	attack_area_scale_multiplier = max(0.01, p_attack_area_scale_multiplier)

	damage_components.clear()

	for component: DamageComponentDefinition in p_damage_components:
		if component == null:
			continue

		var duplicated_component: DamageComponentDefinition = (
			component.duplicate(true) as DamageComponentDefinition
		)

		damage_components.append(duplicated_component)

	attack_areas.clear()

	for attack_area: AttackAreaDefinition in p_attack_areas:
		if attack_area == null or not attack_area.is_valid_definition():
			continue

		var duplicated_area: AttackAreaDefinition = (
			attack_area.duplicate(true) as AttackAreaDefinition
		)

		attack_areas.append(duplicated_area)

	rotation = attack_direction.angle()
	elapsed_seconds = 0.0

	_build_runtime_shapes()

	if runtime_shape_nodes.is_empty():
		push_warning(
			"[DirectionalAttackHitbox] Nenhuma área ofensiva válida configurada: %s"
			% source_id
		)

	is_configured = true
	queue_redraw()

## Configura a hitbox para existir somente na layer de ataque do player
## e detectar somente hurtboxes de inimigos.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(attack_collision_layer_number, true)
	set_collision_mask_value(target_hurtbox_mask_number, true)

## Constrói shapes físicas runtime a partir dos resources da arma.
func _build_runtime_shapes() -> void:
	_clear_runtime_shapes()

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null or not attack_area.is_valid_definition():
			continue

		var runtime_shape: Shape2D = attack_area.build_runtime_shape(
			attack_area_scale_multiplier
		)

		if runtime_shape == null:
			continue

		var shape_node: CollisionShape2D = CollisionShape2D.new()
		shape_node.name = "RuntimeAttackShape_%s" % str(runtime_shape_nodes.size())
		shape_node.shape = runtime_shape
		shape_node.position = attack_area.local_offset
		shape_node.rotation_degrees = attack_area.local_rotation_degrees

		add_child(shape_node)
		runtime_shape_nodes.append(shape_node)

## Remove shapes runtime antigas, caso a instância seja reconfigurada.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()

## Recebe o signal emitido quando uma área vulnerável entra no ataque.
func _on_area_entered(area: Area2D) -> void:
	_try_apply_damage_to_hurtbox(area)

## Também consulta áreas já sobrepostas no frame físico atual.
##
## Isso cobre o caso em que a hitbox nasce já sobre uma hurtbox,
## algo comum em ataques corpo a corpo de curta duração.
func _process_current_overlaps() -> void:
	for overlapping_area: Area2D in get_overlapping_areas():
		_try_apply_damage_to_hurtbox(overlapping_area)

## Encaminha dano somente para HurtboxComponent válidas.
func _try_apply_damage_to_hurtbox(area: Area2D) -> void:
	if not is_configured:
		return

	if not area is HurtboxComponent:
		return

	var hurtbox: HurtboxComponent = area as HurtboxComponent

	if not hurtbox.can_receive_damage():
		return

	var damage_receiver: Node = hurtbox.get_damage_receiver()

	if damage_receiver == null or not is_instance_valid(damage_receiver):
		return

	var receiver_instance_id: int = int(damage_receiver.get_instance_id())

	if already_hit_instance_ids.has(receiver_instance_id):
		return

	if not damage_receiver.has_method("receive_damage"):
		return

	var payload: DamagePayload = DamagePayload.new(
		raw_damage,
		damage_type,
		source_node,
		source_id,
		source_id
	)

	if not damage_components.is_empty():
		payload.set_components(damage_components)

	var final_damage_variant: Variant = damage_receiver.call(
		"receive_damage",
		payload
	)

	var final_damage: int = 0

	if final_damage_variant is int:
		final_damage = int(final_damage_variant)
	elif final_damage_variant is float:
		final_damage = int(final_damage_variant)

	if final_damage <= 0:
		return

	already_hit_instance_ids[receiver_instance_id] = true

	DeveloperAuditLogger.log_combat(
		"Hurtbox atingida: receiver=%s raw_total=%s final=%s components=%s areas=%s" % [
			damage_receiver.name,
			str(payload.get_total_raw_damage()),
			str(final_damage),
			_get_component_debug_string(),
			_get_attack_area_debug_string()
		],
		"DirectionalAttackHitbox",
		{
			"receiver_name": damage_receiver.name,
			"raw_total": payload.get_total_raw_damage(),
			"final_damage": final_damage,
			"components": _get_component_debug_string(),
			"attack_areas": _get_attack_area_debug_string(),
			"source_id": source_id
		}
	)

## Retorna componentes de dano em formato compacto.
func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(raw_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [
			component.damage_type,
			str(component.amount)
		])

	return ", ".join(parts)

## Retorna áreas ofensivas em formato compacto.
func _get_attack_area_debug_string() -> String:
	var parts: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		parts.append(
			attack_area.get_debug_summary(attack_area_scale_multiplier)
		)

	if parts.is_empty():
		return "none"

	return ", ".join(parts)
