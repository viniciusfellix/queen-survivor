## Área de impacto do dash da Queen.
##
## Responsabilidades:
## - detectar EnemyHurtbox durante o dash;
## - aplicar knockback configurável no receiver;
## - respeitar hit único por inimigo quando configurado;
## - manter BodyCollision fora do sistema de efeito.
##
## Esta área não causa dano.
## Ela apenas solicita knockback ao inimigo atingido.
extends Area2D
class_name PlayerDashImpactArea

@export_group("Collision Filter")

## Layer usada por esta área de impacto.
##
## Layer 4 = PlayerAttackHitbox.
@export_range(1, 32, 1) var impact_collision_layer_number: int = 4

## Layer 5 = EnemyHurtbox.
@export_range(1, 32, 1) var enemy_hurtbox_mask_number: int = 5

@export_group("Debug")

## Liga logs temporários para diagnosticar ativação e impactos do dash.
@export var log_dash_impact_debug: bool = true

var dash_definition: QueenDashDefinition = null
var source_node: Node = null
var source_id: String = ""
var dash_direction: Vector2 = Vector2.RIGHT

var runtime_shape_nodes: Array[CollisionShape2D] = []
var already_impacted_instance_ids: Dictionary = {}

var is_configured: bool = false
var is_active: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = false

	_configure_collision_filter()

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

## Configura a área de impacto com o dash atual da Queen.
func setup(
	p_dash_definition: QueenDashDefinition,
	p_source_node: Node,
	p_source_id: String = ""
) -> void:
	source_node = p_source_node
	source_id = p_source_id

	if p_dash_definition == null or not p_dash_definition.is_valid_definition():
		dash_definition = null
		is_configured = false
		set_impact_active(false)
		_clear_runtime_shapes()
		return

	dash_definition = p_dash_definition.duplicate(true) as QueenDashDefinition

	if source_id.strip_edges() == "":
		source_id = dash_definition.impact_source_id

	_build_runtime_shapes()

	is_configured = not runtime_shape_nodes.is_empty()
	set_impact_active(false)

	if log_dash_impact_debug:
		DeveloperAuditLogger.log_combat(
			"DashImpactArea configurada: source=%s configured=%s shapes=%s impact=%s areas_valid=%s" % [
				source_id,
				str(is_configured),
				str(runtime_shape_nodes.size()),
				str(dash_definition.impact_enabled),
				str(dash_definition.has_valid_impact_areas())
			],
			"PlayerDashImpactArea",
			{
				"source_id": source_id,
				"is_configured": is_configured,
				"shape_count": runtime_shape_nodes.size(),
				"impact_enabled": dash_definition.impact_enabled,
				"has_valid_impact_areas": dash_definition.has_valid_impact_areas()
			}
		)

## Ativa a área durante uma execução específica de dash.
func activate_for_dash(direction: Vector2) -> void:
	if not is_configured:
		if log_dash_impact_debug:
			DeveloperAuditLogger.log_combat(
				"DashImpactArea não ativada: is_configured=false",
				"PlayerDashImpactArea"
			)
		return

	if dash_definition == null:
		return

	if not dash_definition.impact_enabled:
		return

	if direction.length() > 0.001:
		dash_direction = direction.normalized()
	else:
		dash_direction = Vector2.RIGHT

	rotation = dash_direction.angle()
	already_impacted_instance_ids.clear()

	# Ativação imediata para garantir detecção durante dash curto.
	monitoring = true
	is_active = true

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.disabled = false

	if log_dash_impact_debug:
		DeveloperAuditLogger.log_combat(
			"DashImpactArea ativada: direction=%s shapes=%s" % [
				str(dash_direction),
				str(runtime_shape_nodes.size())
			],
			"PlayerDashImpactArea",
			{
				"direction": dash_direction,
				"shape_count": runtime_shape_nodes.size()
			}
		)

	call_deferred("_process_current_overlaps")

## Desativa a área ao final do dash.
func deactivate() -> void:
	is_active = false
	monitoring = false
	already_impacted_instance_ids.clear()

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.disabled = true

## Habilita/desabilita a monitoração física da área.
func set_impact_active(should_be_active: bool) -> void:
	is_active = should_be_active
	monitoring = should_be_active

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.disabled = not should_be_active

## Processa overlaps enquanto o dash está ativo.
func _physics_process(_delta: float) -> void:
	if not is_active:
		return

	if not is_configured:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	_process_current_overlaps()

## Recebe entrada de uma EnemyHurtbox na área de impacto.
func _on_area_entered(area: Area2D) -> void:
	_try_apply_dash_impact_to_hurtbox(area)

## Consulta áreas já sobrepostas no frame atual.
func _process_current_overlaps() -> void:
	if not is_active:
		return

	for overlapping_area: Area2D in get_overlapping_areas():
		_try_apply_dash_impact_to_hurtbox(overlapping_area)

## Aplica knockback em receivers válidos via EnemyHurtbox.
func _try_apply_dash_impact_to_hurtbox(area: Area2D) -> void:
	if not is_active:
		return

	if dash_definition == null:
		return

	if not area is HurtboxComponent:
		return

	var hurtbox: HurtboxComponent = area as HurtboxComponent

	var receiver: Node = hurtbox.get_damage_receiver()

	if receiver == null or not is_instance_valid(receiver):
		return

	if not receiver.has_method("apply_hit_knockback"):
		return

	var receiver_instance_id: int = int(receiver.get_instance_id())

	if dash_definition.hit_once_per_enemy and already_impacted_instance_ids.has(receiver_instance_id):
		return

	var result_variant: Variant = receiver.call(
		"apply_hit_knockback",
		dash_definition.impact_knockback_pixels,
		dash_definition.impact_knockback_duration_seconds,
		null,
		dash_direction
	)

	var applied: bool = false

	if result_variant is bool:
		applied = bool(result_variant)

	if not applied:
		return

	already_impacted_instance_ids[receiver_instance_id] = true

	if log_dash_impact_debug:
		DeveloperAuditLogger.log_combat(
			"Dash impact aplicado: receiver=%s knockback=%spx duration=%s" % [
				receiver.name,
				str(dash_definition.impact_knockback_pixels),
				str(dash_definition.impact_knockback_duration_seconds)
			],
			"PlayerDashImpactArea",
			{
				"receiver": receiver.name,
				"source_id": source_id,
				"knockback_pixels": dash_definition.impact_knockback_pixels,
				"duration": dash_definition.impact_knockback_duration_seconds
			}
		)

## Configura layer/mask ofensiva do dash.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(impact_collision_layer_number, true)
	set_collision_mask_value(enemy_hurtbox_mask_number, true)

## Constrói shapes runtime a partir das áreas de impacto do dash.
func _build_runtime_shapes() -> void:
	_clear_runtime_shapes()

	if dash_definition == null:
		return

	for impact_area: AttackAreaDefinition in dash_definition.impact_areas:
		if impact_area == null:
			continue

		if not impact_area.is_valid_definition():
			continue

		var duplicated_area: AttackAreaDefinition = (
			impact_area.duplicate(true) as AttackAreaDefinition
		)

		var runtime_shape: Shape2D = duplicated_area.build_runtime_shape()

		if runtime_shape == null:
			continue

		var shape_node: CollisionShape2D = CollisionShape2D.new()
		shape_node.name = "RuntimeDashImpactShape_%s" % str(runtime_shape_nodes.size())
		shape_node.shape = runtime_shape
		shape_node.position = duplicated_area.local_offset
		shape_node.rotation_degrees = duplicated_area.local_rotation_degrees
		shape_node.disabled = true

		add_child(shape_node)
		runtime_shape_nodes.append(shape_node)

## Remove shapes antigas.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()
