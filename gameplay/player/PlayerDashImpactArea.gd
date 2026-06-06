extends Area2D
class_name PlayerDashImpactArea

@export_group("Collision Filter")
@export_range(1, 32, 1) var impact_collision_layer_number: int = 4
@export_range(1, 32, 1) var enemy_hurtbox_mask_number: int = 5

@export_group("Debug")
@export var log_dash_impact_debug: bool = false

var dash_definition: QueenDashDefinition = null
var source_node: Node = null
var source_id: String = ""
var dash_direction: Vector2 = Vector2.RIGHT
var impact_area_scale_multiplier: float = 1.0

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

func setup(
	p_dash_definition: QueenDashDefinition,
	p_source_node: Node,
	p_source_id: String = "",
	p_impact_area_scale_multiplier: float = 1.0
) -> void:
	source_node = p_source_node
	source_id = p_source_id
	impact_area_scale_multiplier = max(0.01, p_impact_area_scale_multiplier)

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

	is_configured = (
		not runtime_shape_nodes.is_empty()
		and (
			dash_definition.impact_enabled
			or dash_definition.impact_damage_enabled
		)
	)

	set_impact_active(false)

func activate_for_dash(direction: Vector2) -> void:
	if not is_configured:
		return

	if dash_definition == null:
		return

	if direction.length() > 0.001:
		dash_direction = direction.normalized()
	else:
		dash_direction = Vector2.RIGHT

	rotation = dash_direction.angle()
	already_impacted_instance_ids.clear()
	set_impact_active(true)
	call_deferred("_process_current_overlaps")

func deactivate() -> void:
	set_impact_active(false)
	already_impacted_instance_ids.clear()

func set_impact_active(should_be_active: bool) -> void:
	is_active = should_be_active
	monitoring = should_be_active

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.disabled = not should_be_active

func _physics_process(_delta: float) -> void:
	if not is_active:
		return

	if not is_configured:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	_process_current_overlaps()

func _on_area_entered(area: Area2D) -> void:
	_try_apply_dash_impact_to_hurtbox(area)

func _process_current_overlaps() -> void:
	if not is_active:
		return

	for overlapping_area: Area2D in get_overlapping_areas():
		_try_apply_dash_impact_to_hurtbox(overlapping_area)

func _try_apply_dash_impact_to_hurtbox(area: Area2D) -> void:
	if not is_active:
		return

	if dash_definition == null:
		return

	if not (area is HurtboxComponent):
		return

	var hurtbox: HurtboxComponent = area as HurtboxComponent
	var receiver: Node = hurtbox.get_damage_receiver()

	if receiver == null or not is_instance_valid(receiver):
		return

	var receiver_instance_id: int = int(receiver.get_instance_id())

	if dash_definition.hit_once_per_enemy and already_impacted_instance_ids.has(receiver_instance_id):
		return

	var applied_damage: bool = _try_apply_dash_damage(receiver)
	var applied_knockback: bool = _try_apply_dash_knockback(receiver)

	if not applied_damage and not applied_knockback:
		return

	already_impacted_instance_ids[receiver_instance_id] = true

func _try_apply_dash_damage(receiver: Node) -> bool:
	if not dash_definition.impact_damage_enabled:
		return false

	if not dash_definition.has_valid_impact_damage():
		return false

	if not receiver.has_method("receive_damage"):
		return false

	var payload: DamagePayload = DamagePayload.new(
		dash_definition.impact_raw_damage,
		dash_definition.impact_damage_type,
		source_node,
		source_id,
		source_id
	)

	if not dash_definition.impact_damage_components.is_empty():
		payload.set_components(dash_definition.impact_damage_components)

	var result_variant: Variant = receiver.call("receive_damage", payload)

	if result_variant is int:
		return int(result_variant) > 0

	if result_variant is float:
		return int(result_variant) > 0

	return false

func _try_apply_dash_knockback(receiver: Node) -> bool:
	if not dash_definition.impact_enabled:
		return false

	if not receiver.has_method("apply_hit_knockback"):
		return false

	var impact_direction: Vector2 = _resolve_impact_direction_for_receiver(receiver)

	var result_variant: Variant = receiver.call(
		"apply_hit_knockback",
		dash_definition.impact_knockback_pixels,
		dash_definition.impact_knockback_duration_seconds,
		null,
		impact_direction,
		dash_definition.impact_knockback_max_velocity_override,
		dash_definition.impact_chase_weight_override
	)

	if result_variant is bool:
		return bool(result_variant)

	return false

func _resolve_impact_direction_for_receiver(receiver: Node) -> Vector2:
	if dash_definition == null:
		return dash_direction.normalized()

	if dash_definition.impact_direction_mode == "dash_direction":
		return dash_direction.normalized()

	if dash_definition.impact_direction_mode == "away_from_gaia":
		if receiver is Node2D and source_node is Node2D:
			var receiver_node: Node2D = receiver as Node2D
			var source_node_2d: Node2D = source_node as Node2D
			var away_from_gaia: Vector2 = receiver_node.global_position - source_node_2d.global_position

			if away_from_gaia.length() > 0.001:
				return away_from_gaia.normalized()

		return dash_direction.normalized()

	return _resolve_corridor_impact_direction(receiver)

func _resolve_corridor_impact_direction(receiver: Node) -> Vector2:
	if not (receiver is Node2D):
		return dash_direction.normalized()

	var receiver_node: Node2D = receiver as Node2D
	var safe_dash_direction: Vector2 = dash_direction

	if safe_dash_direction.length() <= 0.001:
		safe_dash_direction = Vector2.RIGHT

	safe_dash_direction = safe_dash_direction.normalized()

	var lateral_direction: Vector2 = Vector2(
		-safe_dash_direction.y,
		safe_dash_direction.x
	).normalized()

	var reference_position: Vector2 = global_position

	if source_node is Node2D:
		var source_node_2d: Node2D = source_node as Node2D
		reference_position = source_node_2d.global_position

	var to_receiver: Vector2 = receiver_node.global_position - reference_position
	var side_value: float = to_receiver.dot(lateral_direction)
	var side_sign: float = 1.0

	if side_value < -0.001:
		side_sign = -1.0
	elif side_value > 0.001:
		side_sign = 1.0
	else:
		if int(receiver_node.get_instance_id()) % 2 == 0:
			side_sign = -1.0
		else:
			side_sign = 1.0

	var corridor_direction: Vector2 = lateral_direction * side_sign

	if dash_definition.impact_forward_component > 0.0:
		corridor_direction += safe_dash_direction * dash_definition.impact_forward_component

	if corridor_direction.length() <= 0.001:
		return safe_dash_direction

	return corridor_direction.normalized()

func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(impact_collision_layer_number, true)
	set_collision_mask_value(enemy_hurtbox_mask_number, true)

func _build_runtime_shapes() -> void:
	_clear_runtime_shapes()

	if dash_definition == null:
		return

	for impact_area: AttackAreaDefinition in dash_definition.impact_areas:
		if impact_area == null:
			continue

		if not impact_area.is_valid_definition():
			continue

		var duplicated_area: AttackAreaDefinition = impact_area.duplicate(true) as AttackAreaDefinition
		var runtime_shape: Shape2D = duplicated_area.build_runtime_shape(impact_area_scale_multiplier)

		if runtime_shape == null:
			continue

		var shape_node: CollisionShape2D = CollisionShape2D.new()
		shape_node.name = "RuntimeDashImpactShape_%s" % str(runtime_shape_nodes.size())
		shape_node.shape = runtime_shape
		shape_node.position = duplicated_area.local_offset * impact_area_scale_multiplier
		shape_node.rotation_degrees = duplicated_area.local_rotation_degrees
		shape_node.disabled = true

		add_child(shape_node)
		runtime_shape_nodes.append(shape_node)

func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()
