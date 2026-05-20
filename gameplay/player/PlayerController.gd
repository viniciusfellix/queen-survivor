extends CharacterBody2D

@export var queen_definition: QueenDefinition
@export var runtime_state: PlayerRuntimeState

@export var visual_controller_path: NodePath

@export var draw_debug_aim: bool = true
@export var debug_aim_line_length: float = 96.0

@export var base_defense_percent: float = 0.0

@onready var visual_controller: Node = _resolve_visual_controller()

func _ready() -> void:
	add_to_group("player")

	if runtime_state == null:
		runtime_state = PlayerRuntimeState.new()

	if queen_definition != null:
		runtime_state.setup_from_queen_definition(queen_definition)
	else:
		push_warning("[PlayerController] queen_definition não configurada.")

	runtime_state.defense_percent = base_defense_percent

	if visual_controller == null:
		push_warning("[PlayerController] visual_controller não encontrado. Verifique visual_controller_path.")
		GameEvents.emit_debug("[PlayerController] Visual controller NÃO encontrado.")
	else:
		GameEvents.emit_debug("[PlayerController] Visual controller encontrado: %s" % visual_controller.name)

	_update_visual_state()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if runtime_state == null:
		return

	InputManager.update_input_for_player(global_position)

	var move_direction: Vector2 = InputManager.get_move_direction()
	var aim_direction: Vector2 = InputManager.get_aim_direction()

	if not runtime_state.is_alive:
		runtime_state.apply_input(Vector2.ZERO, aim_direction)
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	runtime_state.apply_input(move_direction, aim_direction)

	velocity = runtime_state.move_direction * runtime_state.move_speed
	move_and_slide()

	_update_visual_state()
	queue_redraw()

func _draw() -> void:
	if not draw_debug_aim:
		return

	if runtime_state == null:
		return

	var aim: Vector2 = runtime_state.aim_direction

	if aim.length() <= 0.001:
		aim = Vector2.RIGHT

	var end_position: Vector2 = aim.normalized() * debug_aim_line_length

	draw_line(Vector2.ZERO, end_position, Color.YELLOW, 3.0)
	draw_circle(Vector2.ZERO, 5.0, Color.WHITE)
	draw_circle(end_position, 5.0, Color.ORANGE)

func receive_damage(payload: DamagePayload) -> int:
	if runtime_state == null:
		return 0

	if payload == null:
		return 0

	if not payload.is_valid_payload():
		return 0

	if not runtime_state.is_alive:
		return 0

	var final_damage: int = DamageResolver.calculate_received_damage(
		payload.raw_damage,
		runtime_state.defense_percent,
		payload.can_be_reduced_by_defense
	)

	runtime_state.apply_damage(final_damage, payload.source_id)

	GameEvents.player_damaged.emit(
		payload.raw_damage,
		final_damage,
		runtime_state.current_hp,
		runtime_state.max_hp,
		payload.source_id
	)

	GameEvents.emit_debug("[PlayerController] Dano recebido: raw=%s final=%s HP=%s/%s fonte=%s" % [
		str(payload.raw_damage),
		str(final_damage),
		str(runtime_state.current_hp),
		str(runtime_state.max_hp),
		payload.source_id
	])

	if not runtime_state.is_alive:
		GameEvents.player_died.emit(payload.source_id)
		GameEvents.emit_debug("[PlayerController] Gaia morreu. Causa: %s" % payload.source_id)

	_update_visual_state()
	queue_redraw()

	return final_damage

func _update_visual_state() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	if visual_controller.has_method("apply_runtime_state"):
		visual_controller.call("apply_runtime_state", runtime_state)

func _resolve_visual_controller() -> Node:
	if visual_controller_path != NodePath():
		var configured_visual: Node = get_node_or_null(visual_controller_path)

		if configured_visual != null:
			return configured_visual

	var direct_visual: Node = get_node_or_null("VisualRoot/GaiaVisual")

	if direct_visual != null:
		return direct_visual

	var visual_root: Node = get_node_or_null("VisualRoot")

	if visual_root != null:
		var found_visual: Node = _find_node_with_method(visual_root, "apply_runtime_state")

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

func apply_run_upgrade(upgrade: UpgradeDefinition) -> void:
	if upgrade == null:
		return

	if runtime_state == null:
		return

	match upgrade.upgrade_type:
		UpgradeTypes.PLAYER_MOVE_SPEED_PERCENT:
			var multiplier: float = 1.0 + (upgrade.value_float * 0.01)
			runtime_state.move_speed *= multiplier

			GameEvents.emit_debug("[PlayerController] Upgrade aplicado: velocidade +%s%% | move_speed=%s" % [
				str(upgrade.value_float),
				str(runtime_state.move_speed)
			])

		UpgradeTypes.PLAYER_MAX_HP_FLAT:
			var hp_gain: int = max(0, upgrade.value_int)

			runtime_state.max_hp += hp_gain
			runtime_state.current_hp = min(runtime_state.max_hp, runtime_state.current_hp + hp_gain)

			GameEvents.emit_debug("[PlayerController] Upgrade aplicado: HP máximo +%s | HP=%s/%s" % [
				str(hp_gain),
				str(runtime_state.current_hp),
				str(runtime_state.max_hp)
			])

		_:
			_forward_upgrade_to_weapons(upgrade)

	_update_visual_state()
	queue_redraw()

func _forward_upgrade_to_weapons(upgrade: UpgradeDefinition) -> void:
	var weapon_nodes: Array[Node] = get_tree().get_nodes_in_group("player_weapon")

	var applied_count: int = 0

	for weapon_node: Node in weapon_nodes:
		if weapon_node.has_method("apply_run_upgrade"):
			weapon_node.call("apply_run_upgrade", upgrade)
			applied_count += 1

	GameEvents.emit_debug("[PlayerController] Upgrade encaminhado para armas: %s | count=%s" % [
		upgrade.id,
		str(applied_count)
	])

func get_runtime_state() -> PlayerRuntimeState:
	return runtime_state

func get_debug_data() -> Dictionary:
	if runtime_state == null:
		return {
			"has_runtime_state": false
		}

	return {
		"has_runtime_state": true,
		"queen_id": runtime_state.queen_id,
		"current_hp": runtime_state.current_hp,
		"max_hp": runtime_state.max_hp,
		"defense_percent": runtime_state.defense_percent,
		"move_speed": runtime_state.move_speed,
		"move_direction": runtime_state.move_direction,
		"aim_direction": runtime_state.aim_direction,
		"last_valid_aim_direction": runtime_state.last_valid_aim_direction,
		"facing_direction": runtime_state.facing_direction,
		"is_moving": runtime_state.is_moving,
		"is_alive": runtime_state.is_alive,
		"current_gameplay_state": runtime_state.current_gameplay_state,
		"current_visual_state": runtime_state.current_visual_state,
		"global_position": global_position,
		"total_damage_taken": runtime_state.total_damage_taken,
		"last_damage_taken": runtime_state.last_damage_taken,
		"last_damage_source_id": runtime_state.last_damage_source_id,
		"death_cause": runtime_state.death_cause
	}
