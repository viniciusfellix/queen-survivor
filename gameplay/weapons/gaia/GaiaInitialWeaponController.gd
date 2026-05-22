extends Node

@export var weapon_definition: WeaponDefinition

@export_file("*.tscn") var attack_visual_scene_path: String = "res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn"
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

@export var attack_visual_root_path: NodePath
@export var attack_hitbox_root_path: NodePath

@export var weapon_enabled: bool = true

# Se true, a arma dispara assim que a cena começa.
# Para gameplay normal, manter false.
@export var attack_on_ready: bool = false

# Se attack_on_ready estiver false, este valor define o delay inicial.
# Se for <= 0, usa cooldown_seconds.
@export var initial_attack_delay_seconds: float = -1.0

@export var emit_cooldown_updates: bool = true

@export var cooldown_seconds: float = 2.0

@export var attack_visual_offset: float = 86.0
@export var attack_visual_lifetime: float = 0.22
@export var attack_visual_scale: Vector2 = Vector2.ONE

@export var attack_hitbox_offset: float = 86.0
@export var attack_hitbox_radius: float = 72.0
@export var attack_hitbox_lifetime: float = 0.12

# Fallback simples.
@export var base_damage: int = 5
@export var damage_type: String = DamageTypes.PHYSICAL

# Modelo oficial.
@export var damage_components: Array[DamageComponentDefinition] = []

@export var weapon_source_id: String = "gaia_initial_weapon"

@export_group("Damage Interrupt")
@export var reset_cooldown_when_player_damaged: bool = true
@export var damage_reset_cooldown_ratio: float = 1.0

var cooldown_timer: float = 0.0

var player_controller: Node = null
var attack_visual_root: Node2D = null
var attack_hitbox_root: Node2D = null

func _ready() -> void:
	add_to_group("player_weapon")
	
	_apply_weapon_definition()

	player_controller = _resolve_player_controller()
	attack_visual_root = _resolve_attack_visual_root()
	attack_hitbox_root = _resolve_attack_hitbox_root()

	if player_controller != null:
		GameEvents.emit_debug("[GaiaInitialWeaponController] Player controller encontrado: %s" % player_controller.name)
	else:
		GameEvents.emit_debug("[GaiaInitialWeaponController] Player controller NÃO encontrado.")

	if attack_visual_root != null:
		GameEvents.emit_debug("[GaiaInitialWeaponController] AttackVisualRoot encontrado: %s" % attack_visual_root.name)
	else:
		GameEvents.emit_debug("[GaiaInitialWeaponController] AttackVisualRoot NÃO encontrado.")

	if attack_hitbox_root != null:
		GameEvents.emit_debug("[GaiaInitialWeaponController] AttackHitboxRoot encontrado: %s" % attack_hitbox_root.name)
	else:
		GameEvents.emit_debug("[GaiaInitialWeaponController] AttackHitboxRoot NÃO encontrado.")

	if attack_on_ready:
		cooldown_timer = 0.0
	else:
		cooldown_timer = _get_initial_attack_delay()
	
	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	_emit_cooldown_update()

func _process(delta: float) -> void:
	if not weapon_enabled:
		return

	if player_controller == null:
		player_controller = _resolve_player_controller()

	if attack_visual_root == null:
		attack_visual_root = _resolve_attack_visual_root()

	if attack_hitbox_root == null:
		attack_hitbox_root = _resolve_attack_hitbox_root()

	if player_controller == null or attack_visual_root == null or attack_hitbox_root == null:
		return

	var runtime_state: PlayerRuntimeState = _get_player_runtime_state()

	if runtime_state == null:
		return

	if not runtime_state.is_alive:
		return

	cooldown_timer -= delta
	
	cooldown_timer = max(0.0, cooldown_timer)
	_emit_cooldown_update()

	if cooldown_timer <= 0.0:
		_fire_attack(runtime_state)
		cooldown_timer = cooldown_seconds

func force_fire() -> void:
	var runtime_state: PlayerRuntimeState = _get_player_runtime_state()

	if runtime_state == null:
		return

	_fire_attack(runtime_state)
	cooldown_timer = cooldown_seconds

func _fire_attack(runtime_state: PlayerRuntimeState) -> void:
	var direction: Vector2 = _resolve_attack_direction(runtime_state)

	_spawn_attack_visual(direction)
	_spawn_attack_hitbox(direction)

	GameEvents.emit_debug("[GaiaInitialWeaponController] Ataque disparado. direction=%s raw_total=%s components=%s" % [
		str(direction),
		str(_get_total_raw_damage()),
		_get_component_debug_string()
	])

func _spawn_attack_visual(direction: Vector2) -> void:
	var packed_visual: PackedScene = load(attack_visual_scene_path) as PackedScene

	if packed_visual == null:
		push_warning("[GaiaInitialWeaponController] Não foi possível carregar attack_visual_scene_path: %s" % attack_visual_scene_path)
		return

	var visual_instance: Node = packed_visual.instantiate()

	if not visual_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack visual não é Node2D.")
		visual_instance.queue_free()
		return

	var visual_node: Node2D = visual_instance as Node2D

	attack_visual_root.add_child(visual_node)
	visual_node.global_position = _get_player_global_position() + direction * attack_visual_offset

	if visual_node.has_method("setup"):
		visual_node.call("setup", direction, attack_visual_lifetime, attack_visual_scale)

func _spawn_attack_hitbox(direction: Vector2) -> void:
	var packed_hitbox: PackedScene = load(attack_hitbox_scene_path) as PackedScene

	if packed_hitbox == null:
		push_warning("[GaiaInitialWeaponController] Não foi possível carregar attack_hitbox_scene_path: %s" % attack_hitbox_scene_path)
		return

	var hitbox_instance: Node = packed_hitbox.instantiate()

	if not hitbox_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack hitbox não é Node2D.")
		hitbox_instance.queue_free()
		return

	var hitbox_node: Node2D = hitbox_instance as Node2D

	attack_hitbox_root.add_child(hitbox_node)
	hitbox_node.global_position = _get_player_global_position() + direction * attack_hitbox_offset

	if hitbox_node.has_method("setup"):
		hitbox_node.call(
			"setup",
			player_controller,
			direction,
			base_damage,
			damage_type,
			attack_hitbox_radius,
			attack_hitbox_lifetime,
			weapon_source_id,
			damage_components
		)

func _resolve_attack_direction(runtime_state: PlayerRuntimeState) -> Vector2:
	var direction: Vector2 = runtime_state.aim_direction

	if direction.length() <= 0.001:
		direction = runtime_state.last_valid_aim_direction

	if direction.length() <= 0.001:
		direction = Vector2.RIGHT

	return direction.normalized()

func _apply_weapon_definition() -> void:
	if weapon_definition == null:
		return

	if weapon_definition.attack_visual_scene_path.strip_edges() != "":
		attack_visual_scene_path = weapon_definition.attack_visual_scene_path

	if weapon_definition.attack_hitbox_scene_path.strip_edges() != "":
		attack_hitbox_scene_path = weapon_definition.attack_hitbox_scene_path

	cooldown_seconds = weapon_definition.cooldown_seconds

	attack_visual_offset = weapon_definition.attack_visual_offset
	attack_visual_lifetime = weapon_definition.attack_visual_lifetime

	attack_hitbox_offset = weapon_definition.attack_hitbox_offset
	attack_hitbox_radius = weapon_definition.attack_hitbox_radius
	attack_hitbox_lifetime = weapon_definition.attack_hitbox_lifetime

	base_damage = weapon_definition.base_damage
	damage_type = weapon_definition.damage_type

	if weapon_definition.has_damage_components():
		damage_components.clear()

		for component: DamageComponentDefinition in weapon_definition.damage_components:
			if component == null:
				continue

			var duplicated_component: DamageComponentDefinition = component.duplicate(true) as DamageComponentDefinition
			damage_components.append(duplicated_component)
	else:
		damage_components.clear()

	weapon_source_id = weapon_definition.id

	GameEvents.emit_debug("[GaiaInitialWeaponController] Config aplicada: fallback_damage=%s components=%s visual_offset=%s hitbox_offset=%s hitbox_radius=%s cooldown=%s" % [
		str(base_damage),
		_get_component_debug_string(),
		str(attack_visual_offset),
		str(attack_hitbox_offset),
		str(attack_hitbox_radius),
		str(cooldown_seconds)
	])

func _get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return base_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(base_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [component.damage_type, str(component.amount)])

	return ", ".join(parts)

func _get_player_runtime_state() -> PlayerRuntimeState:
	if player_controller == null:
		return null

	if not player_controller.has_method("get_runtime_state"):
		return null

	var runtime_state_variant: Variant = player_controller.call("get_runtime_state")

	if runtime_state_variant is PlayerRuntimeState:
		return runtime_state_variant as PlayerRuntimeState

	return null

func _resolve_player_controller() -> Node:
	var current: Node = self

	while current != null:
		if current.has_method("get_runtime_state"):
			return current

		current = current.get_parent()

	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	for player: Node in players:
		if player.has_method("get_runtime_state"):
			return player

	return null

func _resolve_attack_visual_root() -> Node2D:
	if attack_visual_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_visual_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackVisualRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

func _resolve_attack_hitbox_root() -> Node2D:
	if attack_hitbox_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_hitbox_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackHitboxRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

func _get_player_global_position() -> Vector2:
	if player_controller is Node2D:
		var player_node: Node2D = player_controller as Node2D
		return player_node.global_position

	return Vector2.ZERO

func apply_run_upgrade(upgrade: UpgradeDefinition) -> void:
	if upgrade == null:
		return

	match upgrade.upgrade_type:
		UpgradeTypes.WEAPON_DAMAGE_FLAT:
			_apply_damage_flat_upgrade(upgrade.value_int)

		UpgradeTypes.WEAPON_COOLDOWN_PERCENT:
			_apply_cooldown_percent_upgrade(upgrade.value_float)

		UpgradeTypes.WEAPON_PHYSICAL_DAMAGE_FLAT:
			_apply_component_damage_flat_upgrade(DamageTypes.PHYSICAL, upgrade.value_int)

		UpgradeTypes.WEAPON_MAGICAL_DAMAGE_FLAT:
			_apply_component_damage_flat_upgrade(DamageTypes.MAGICAL, upgrade.value_int)

		UpgradeTypes.WEAPON_HITBOX_RADIUS_FLAT:
			_apply_hitbox_radius_flat_upgrade(upgrade.value_int)

		UpgradeTypes.WEAPON_HITBOX_LIFETIME_PERCENT:
			_apply_hitbox_lifetime_percent_upgrade(upgrade.value_float)

		_:
			GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade ignorado pela arma: %s" % upgrade.id)

func _apply_damage_flat_upgrade(amount: int) -> void:
	if amount <= 0:
		return

	if damage_components.is_empty():
		base_damage += amount

		GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade dano aplicado no fallback: +%s | base_damage=%s" % [
			str(amount),
			str(base_damage)
		])
		return

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		component.amount += amount

	GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade dano aplicado nos componentes: +%s | components=%s" % [
		str(amount),
		_get_component_debug_string()
	])

func _apply_cooldown_percent_upgrade(percent: float) -> void:
	if percent <= 0.0:
		return

	var multiplier: float = max(0.05, 1.0 - (percent * 0.01))
	cooldown_seconds = max(0.15, cooldown_seconds * multiplier)

	GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade cooldown aplicado: -%s%% | cooldown=%s" % [
		str(percent),
		str(cooldown_seconds)
	])

func _apply_component_damage_flat_upgrade(damage_type_to_match: String, amount: int) -> void:
	if amount <= 0:
		return

	if damage_components.is_empty():
		GameEvents.emit_debug("[GaiaInitialWeaponController] Sem componentes para aplicar dano específico: %s" % damage_type_to_match)
		return

	var applied_count: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		if component.damage_type != damage_type_to_match:
			continue

		component.amount += amount
		applied_count += 1

	GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade dano %s aplicado: +%s | applied=%s | components=%s" % [
		damage_type_to_match,
		str(amount),
		str(applied_count),
		_get_component_debug_string()
	])

func _apply_hitbox_radius_flat_upgrade(amount: int) -> void:
	if amount <= 0:
		return

	attack_hitbox_radius += float(amount)

	GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade raio da hitbox aplicado: +%s | radius=%s" % [
		str(amount),
		str(attack_hitbox_radius)
	])

func _apply_hitbox_lifetime_percent_upgrade(percent: float) -> void:
	if percent <= 0.0:
		return

	var multiplier: float = 1.0 + (percent * 0.01)
	attack_hitbox_lifetime = min(0.60, attack_hitbox_lifetime * multiplier)

	GameEvents.emit_debug("[GaiaInitialWeaponController] Upgrade duração da hitbox aplicado: +%s%% | lifetime=%s" % [
		str(percent),
		str(attack_hitbox_lifetime)
	])

func _get_initial_attack_delay() -> float:
	if initial_attack_delay_seconds > 0.0:
		return initial_attack_delay_seconds

	return cooldown_seconds

func _emit_cooldown_update() -> void:
	if not emit_cooldown_updates:
		return

	var progress_ratio: float = 1.0

	if cooldown_seconds > 0.0:
		progress_ratio = 1.0 - clamp(cooldown_timer / cooldown_seconds, 0.0, 1.0)

	GameEvents.weapon_cooldown_changed.emit(
		weapon_source_id,
		cooldown_timer,
		cooldown_seconds,
		progress_ratio
	)

func _on_player_damaged(
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if not reset_cooldown_when_player_damaged:
		return

	if final_damage <= 0:
		return

	var ratio: float = clamp(damage_reset_cooldown_ratio, 0.0, 1.0)
	cooldown_timer = cooldown_seconds * ratio

	_emit_cooldown_update()

	GameEvents.emit_debug("[GaiaInitialWeaponController] Cooldown resetado por dano recebido. cooldown_timer=%s" % str(cooldown_timer))
