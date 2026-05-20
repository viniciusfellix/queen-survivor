extends CharacterBody2D

@export var enemy_definition: EnemyDefinition

@export var target_path: NodePath
@export var target_group_name: String = "player"

@export var visual_controller_path: NodePath

@export var stopping_distance: float = 8.0
@export var draw_debug_visual: bool = true
@export var draw_debug_target_line: bool = false
@export var draw_contact_radius: bool = true

@export var remove_after_death_seconds: float = 0.45

var max_hp: int = 10
var current_hp: int = 10
var move_speed: float = 90.0

var contact_damage: int = 5
var contact_damage_radius: float = 32.0
var contact_damage_interval_seconds: float = 1.0
var contact_damage_type: String = "physical"
var xp_reward: int = 1
var coin_drop_chance: float = 0.25
var coin_drop_value: int = 1

var contact_damage_timer: float = 0.0

var target_node: Node2D = null
var visual_controller: Node = null

var enemy_id: String = ""
var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)
var debug_radius: float = 18.0

var is_alive: bool = true
var is_dying: bool = false
var total_damage_taken: int = 0
var last_damage_taken: int = 0
var last_damage_source_id: String = ""

func _ready() -> void:
	add_to_group("enemy")

	visual_controller = _resolve_visual_controller()

	_apply_definition()
	target_node = _resolve_target()

	if target_node != null:
		GameEvents.emit_debug("[EnemyBase] Target encontrado: %s" % target_node.name)
	else:
		GameEvents.emit_debug("[EnemyBase] Nenhum target encontrado no _ready().")

	if visual_controller != null:
		GameEvents.emit_debug("[EnemyBase] Visual controller encontrado: %s" % visual_controller.name)
	else:
		GameEvents.emit_debug("[EnemyBase] Visual controller não encontrado.")

	_update_visual_state()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	_update_contact_damage_timer(delta)

	if target_node == null:
		target_node = _resolve_target()

	if target_node == null:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	_follow_target()
	move_and_slide()

	_try_apply_contact_damage()

	_update_visual_state()
	queue_redraw()

func _draw() -> void:
	if not draw_debug_visual:
		return

	var body_color: Color = debug_color

	if not is_alive:
		body_color = Color(0.25, 0.25, 0.25, 0.7)

	draw_circle(Vector2.ZERO, debug_radius, body_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, Color.WHITE, 2.0)

	if draw_contact_radius and is_alive:
		draw_arc(Vector2.ZERO, contact_damage_radius, 0.0, TAU, 32, Color(1.0, 0.5, 0.1, 0.85), 1.0)

	var forward_direction: Vector2 = Vector2.RIGHT

	if velocity.length() > 0.001:
		forward_direction = velocity.normalized()

	var nose_position: Vector2 = forward_direction * (debug_radius + 8.0)
	draw_circle(nose_position, 4.0, Color.WHITE)

	if draw_debug_target_line and target_node != null:
		var local_target_position: Vector2 = to_local(target_node.global_position)
		draw_line(Vector2.ZERO, local_target_position, Color.YELLOW, 1.0)

func setup(definition: EnemyDefinition, target: Node2D = null) -> void:
	enemy_definition = definition

	if target != null:
		target_node = target

	_apply_definition()

	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	_update_visual_state()
	queue_redraw()

func receive_damage(payload: DamagePayload) -> int:
	if payload == null:
		return 0

	if not payload.is_valid_payload():
		return 0

	if not is_alive:
		return 0

	var damage_result: Dictionary = DamageResolver.calculate_enemy_damage(payload, enemy_definition)
	var final_damage: int = int(damage_result.get("final_total", 0))
	var raw_total: int = int(damage_result.get("raw_total", payload.get_total_raw_damage()))

	if final_damage <= 0:
		return 0

	current_hp = max(0, current_hp - final_damage)
	total_damage_taken += final_damage
	last_damage_taken = final_damage
	last_damage_source_id = payload.source_id

	GameEvents.enemy_damaged.emit(
		enemy_id,
		raw_total,
		final_damage,
		current_hp,
		max_hp,
		payload.source_id
	)

	GameEvents.emit_debug("[EnemyBase] Dano recebido: enemy=%s raw_total=%s final=%s HP=%s/%s fonte=%s breakdown=%s" % [
		enemy_id,
		str(raw_total),
		str(final_damage),
		str(current_hp),
		str(max_hp),
		payload.source_id,
		_format_damage_breakdown(damage_result)
	])

	if current_hp <= 0:
		die(payload.source_id)

	_update_visual_state()
	queue_redraw()

	return final_damage
	
func die(source_id: String = "") -> void:
	if not is_alive:
		return

	is_alive = false
	is_dying = true
	velocity = Vector2.ZERO

	GameEvents.enemy_died.emit(
		enemy_id,
		source_id,
		xp_reward,
		global_position,
		coin_drop_chance,
		coin_drop_value
	)

	GameEvents.emit_debug("[EnemyBase] Inimigo morreu: enemy=%s fonte=%s xp=%s coin_chance=%s coin_value=%s" % [
		enemy_id,
		source_id,
		str(xp_reward),
		str(coin_drop_chance),
		str(coin_drop_value)
	])

	_update_visual_state()

	remove_from_group("enemy")

	var death_timer: SceneTreeTimer = get_tree().create_timer(remove_after_death_seconds)
	death_timer.timeout.connect(_on_death_timer_timeout)
	
func _on_death_timer_timeout() -> void:
	queue_free()

func _apply_definition() -> void:
	if enemy_definition == null:
		enemy_id = "enemy_undefined"
		max_hp = 10
		current_hp = max_hp
		move_speed = 90.0
		
		coin_drop_chance = 0.25
		coin_drop_value = 1

		contact_damage = 5
		contact_damage_radius = 32.0
		contact_damage_interval_seconds = 1.0
		contact_damage_type = "physical"
		xp_reward = 1

		debug_color = Color(0.9, 0.15, 0.15, 1.0)
		debug_radius = 18.0
		return

	enemy_id = enemy_definition.id
	max_hp = enemy_definition.base_max_hp
	current_hp = max_hp
	move_speed = enemy_definition.base_move_speed

	contact_damage = enemy_definition.contact_damage
	contact_damage_radius = enemy_definition.contact_damage_radius
	contact_damage_interval_seconds = enemy_definition.contact_damage_interval_seconds
	contact_damage_type = enemy_definition.contact_damage_type
	
	xp_reward = enemy_definition.xp_reward
	coin_drop_chance = enemy_definition.coin_drop_chance
	coin_drop_value = enemy_definition.coin_drop_value
		
	debug_color = enemy_definition.debug_color
	debug_radius = enemy_definition.debug_radius

func _follow_target() -> void:
	var to_target: Vector2 = target_node.global_position - global_position
	var distance_to_target: float = to_target.length()

	if distance_to_target <= stopping_distance:
		velocity = Vector2.ZERO
		return

	var direction: Vector2 = to_target.normalized()
	velocity = direction * move_speed

func _update_contact_damage_timer(delta: float) -> void:
	if contact_damage_timer > 0.0:
		contact_damage_timer = max(0.0, contact_damage_timer - delta)

func _try_apply_contact_damage() -> void:
	if target_node == null:
		return

	if contact_damage_timer > 0.0:
		return

	if contact_damage <= 0:
		return

	var distance_to_target: float = global_position.distance_to(target_node.global_position)

	if distance_to_target > contact_damage_radius:
		return

	if not target_node.has_method("receive_damage"):
		return

	var payload: DamagePayload = DamagePayload.new(
		contact_damage,
		contact_damage_type,
		self,
		enemy_id,
		enemy_id
	)

	var final_damage_variant: Variant = target_node.call("receive_damage", payload)

	contact_damage_timer = contact_damage_interval_seconds

	GameEvents.emit_debug("[EnemyBase] Dano de contato aplicado. enemy=%s raw=%s final=%s" % [
		enemy_id,
		str(contact_damage),
		str(final_damage_variant)
	])

func _update_visual_state() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	var is_moving: bool = is_alive and velocity.length() > 0.001
	var movement_direction: Vector2 = Vector2.ZERO

	if is_moving:
		movement_direction = velocity.normalized()

	if visual_controller.has_method("apply_enemy_runtime_state"):
		visual_controller.call("apply_enemy_runtime_state", is_moving, movement_direction, is_alive)

func _resolve_visual_controller() -> Node:
	if visual_controller_path != NodePath():
		var configured_visual: Node = get_node_or_null(visual_controller_path)

		if configured_visual != null:
			return configured_visual

	var direct_visual: Node = get_node_or_null("VisualRoot/GoblinWarriorVisual")

	if direct_visual != null:
		return direct_visual

	var visual_root: Node = get_node_or_null("VisualRoot")

	if visual_root != null:
		var found_visual: Node = _find_node_with_method(visual_root, "apply_enemy_runtime_state")

		if found_visual != null:
			return found_visual

	return null

func _find_node_with_method(root: Node, method_name: String) -> Node:
	if root == null:
		return null

	if root.has_method(method_name):
		return root

	for child: Node in root.get_children():
		var found: Node = _find_node_with_method(child, method_name)

		if found != null:
			return found

	return null

func _resolve_target() -> Node2D:
	if target_path != NodePath():
		var configured_target: Node = get_node_or_null(target_path)

		if configured_target is Node2D:
			return configured_target as Node2D

	var group_target: Node2D = _find_first_node2d_in_group(target_group_name)

	if group_target != null:
		return group_target

	return null

func _find_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null

func _format_damage_breakdown(damage_result: Dictionary) -> String:
	var breakdown_variant: Variant = damage_result.get("breakdown", [])

	if not breakdown_variant is Array:
		return ""

	var breakdown: Array = breakdown_variant
	var parts: Array[String] = []

	for entry_variant: Variant in breakdown:
		if not entry_variant is Dictionary:
			continue

		var entry: Dictionary = entry_variant

		parts.append("%s raw=%s final=%s weak=%s resist=%s mult=%s" % [
			str(entry.get("damage_type", "")),
			str(entry.get("raw_damage", 0)),
			str(entry.get("final_damage", 0)),
			str(entry.get("is_weak", false)),
			str(entry.get("is_resistant", false)),
			str(entry.get("multiplier", 1.0))
		])

	return " | ".join(parts)

func get_debug_data() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"move_speed": move_speed,
		"contact_damage": contact_damage,
		"contact_damage_radius": contact_damage_radius,
		"global_position": global_position,
		"has_target": target_node != null,
		"has_visual": visual_controller != null,
		"is_alive": is_alive,
		"total_damage_taken": total_damage_taken,
		"last_damage_taken": last_damage_taken,
		"last_damage_source_id": last_damage_source_id,
		"xp_reward": xp_reward
	}
