## Controller runtime da arma inicial da Gaia.
##
## Responsabilidades:
## - carregar a WeaponDefinition configurada;
## - controlar cooldown dos ataques;
## - utilizar a direção de mira da Gaia;
## - instanciar visual e hitbox do golpe;
## - manter cópias runtime dos componentes de dano;
## - aplicar upgrades da arma durante a run;
## - publicar progresso do cooldown para a HUD.
##
## A geometria da hitbox vem da WeaponDefinition por meio de
## `Array[AttackAreaDefinition]`, permitindo configuração no Inspector.
extends Node

@export_group("Definition")

@export var weapon_definition: WeaponDefinition

@export_group("Scenes")

@export_file("*.tscn") var attack_visual_scene_path: String = "res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn"
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

@export_group("Runtime Roots")

@export var attack_visual_root_path: NodePath
@export var attack_hitbox_root_path: NodePath

@export_group("Behaviour")

@export var weapon_enabled: bool = true

## Se verdadeiro, a arma dispara imediatamente ao iniciar a cena.
## Para gameplay normal, manter falso.
@export var attack_on_ready: bool = false

## Delay inicial antes do primeiro ataque.
## Quando menor ou igual a zero, utiliza o cooldown atual.
@export var initial_attack_delay_seconds: float = -1.0

@export var emit_cooldown_updates: bool = true

@export_group("Cooldown")

@export var cooldown_seconds: float = 2.0

@export_group("Attack Visual")

@export var attack_visual_offset: float = 86.0
@export var attack_visual_lifetime: float = 0.22
@export var attack_visual_scale: Vector2 = Vector2.ONE

@export_group("Attack Hitbox")

## Distância base entre Gaia e o ponto de origem da hitbox.
@export var attack_hitbox_offset: float = 86.0

## Tempo ativo da hitbox.
@export var attack_hitbox_lifetime: float = 0.12

## Fallback para testes sem WeaponDefinition.
## Quando uma WeaponDefinition estiver configurada, suas áreas prevalecem.
@export var attack_areas: Array[AttackAreaDefinition] = []

@export_group("Damage")

## Dano simples usado somente caso não existam componentes cadastrados.
@export var base_damage: int = 5

@export var damage_type: String = DamageTypes.PHYSICAL

## Componentes runtime da arma.
## São duplicados a partir do resource para permitir upgrades durante a run.
@export var damage_components: Array[DamageComponentDefinition] = []

@export var weapon_source_id: String = "gaia_initial_weapon"

var cooldown_timer: float = 0.0

## Multiplicador runtime das áreas ofensivas.
## Inicia em 1.0 e pode crescer por upgrades durante a run.
var attack_area_scale_multiplier: float = 1.0

var player_controller: Node = null
var attack_visual_root: Node2D = null
var attack_hitbox_root: Node2D = null

func _ready() -> void:
	add_to_group("player_weapon")

	_apply_weapon_definition()

	player_controller = _resolve_player_controller()
	attack_visual_root = _resolve_attack_visual_root()
	attack_hitbox_root = _resolve_attack_hitbox_root()

	if player_controller == null:
		push_warning("[GaiaInitialWeaponController] Player controller não encontrado.")

	if attack_visual_root == null:
		push_warning("[GaiaInitialWeaponController] AttackVisualRoot não encontrado.")

	if attack_hitbox_root == null:
		push_warning("[GaiaInitialWeaponController] AttackHitboxRoot não encontrado.")

	if attack_on_ready:
		cooldown_timer = 0.0
	else:
		cooldown_timer = _get_initial_attack_delay()

	_emit_cooldown_update()

func _process(delta: float) -> void:
	if not weapon_enabled:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
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

	if runtime_state == null or not runtime_state.is_alive:
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)

	_emit_cooldown_update()

	if cooldown_timer <= 0.0:
		_fire_attack(runtime_state)
		cooldown_timer = cooldown_seconds

## Dispara manualmente a arma em ferramentas técnicas,
## respeitando bloqueio de gameplay e estado de vida da Gaia.
func force_fire() -> void:
	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	var runtime_state: PlayerRuntimeState = _get_player_runtime_state()

	if runtime_state == null or not runtime_state.is_alive:
		return

	_fire_attack(runtime_state)
	cooldown_timer = cooldown_seconds

## Executa um ataque completo na direção atual da mira.
func _fire_attack(runtime_state: PlayerRuntimeState) -> void:
	var direction: Vector2 = _resolve_attack_direction(runtime_state)

	_spawn_attack_visual(direction)
	_spawn_attack_hitbox(direction)

	DeveloperAuditLogger.log_combat(
		"Ataque disparado: direction=%s raw_total=%s components=%s areas=%s" % [
			str(direction),
			str(_get_total_raw_damage()),
			_get_component_debug_string(),
			_get_attack_area_debug_string()
		],
		"GaiaInitialWeaponController",
		{
			"direction": direction,
			"raw_total": _get_total_raw_damage(),
			"components": _get_component_debug_string(),
			"attack_areas": _get_attack_area_debug_string(),
			"weapon_id": weapon_source_id
		}
	)

## Instancia somente a representação visual do golpe.
func _spawn_attack_visual(direction: Vector2) -> void:
	var packed_visual: PackedScene = load(attack_visual_scene_path) as PackedScene

	if packed_visual == null:
		push_warning(
			"[GaiaInitialWeaponController] Não foi possível carregar attack_visual_scene_path: %s"
			% attack_visual_scene_path
		)
		return

	var visual_instance: Node = packed_visual.instantiate()

	if not visual_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack visual não é Node2D.")
		visual_instance.queue_free()
		return

	var visual_node: Node2D = visual_instance as Node2D

	attack_visual_root.add_child(visual_node)
	visual_node.global_position = (
		_get_player_global_position() + direction * attack_visual_offset
	)

	if visual_node.has_method("setup"):
		visual_node.call(
			"setup",
			direction,
			attack_visual_lifetime,
			attack_visual_scale
		)

## Instancia a hitbox ofensiva e repassa áreas, dano e escala runtime.
func _spawn_attack_hitbox(direction: Vector2) -> void:
	var packed_hitbox: PackedScene = load(attack_hitbox_scene_path) as PackedScene

	if packed_hitbox == null:
		push_warning(
			"[GaiaInitialWeaponController] Não foi possível carregar attack_hitbox_scene_path: %s"
			% attack_hitbox_scene_path
		)
		return

	var hitbox_instance: Node = packed_hitbox.instantiate()

	if not hitbox_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack hitbox não é Node2D.")
		hitbox_instance.queue_free()
		return

	var hitbox_node: Node2D = hitbox_instance as Node2D

	attack_hitbox_root.add_child(hitbox_node)

	hitbox_node.global_position = (
		_get_player_global_position() + direction * attack_hitbox_offset
	)

	if hitbox_node.has_method("setup"):
		hitbox_node.call(
			"setup",
			player_controller,
			direction,
			base_damage,
			damage_type,
			attack_areas,
			attack_hitbox_lifetime,
			weapon_source_id,
			damage_components,
			attack_area_scale_multiplier
		)

## Retorna direção normalizada de mira usada pelo ataque.
func _resolve_attack_direction(runtime_state: PlayerRuntimeState) -> Vector2:
	var direction: Vector2 = runtime_state.aim_direction

	if direction.length() <= 0.001:
		direction = runtime_state.last_valid_aim_direction

	if direction.length() <= 0.001:
		direction = Vector2.RIGHT

	return direction.normalized()

## Copia configuração base do resource para o controller runtime.
##
## Damage components são duplicados porque upgrades os modificam
## durante a run. As áreas não são modificadas diretamente:
## upgrades utilizam `attack_area_scale_multiplier`.
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
	attack_hitbox_lifetime = weapon_definition.attack_hitbox_lifetime

	attack_areas.clear()

	for attack_area: AttackAreaDefinition in weapon_definition.attack_areas:
		if attack_area == null:
			continue

		if not attack_area.is_valid_definition():
			continue

		attack_areas.append(attack_area)

	if attack_areas.is_empty():
		push_warning(
			"[GaiaInitialWeaponController] WeaponDefinition sem áreas de ataque válidas: %s"
			% weapon_definition.id
		)

	attack_area_scale_multiplier = 1.0

	base_damage = weapon_definition.base_damage
	damage_type = weapon_definition.damage_type

	damage_components.clear()

	if weapon_definition.has_damage_components():
		for component: DamageComponentDefinition in weapon_definition.damage_components:
			if component == null:
				continue

			var duplicated_component: DamageComponentDefinition = (
				component.duplicate(true) as DamageComponentDefinition
			)

			damage_components.append(duplicated_component)

	weapon_source_id = weapon_definition.id

	DeveloperAuditLogger.log_scene(
		"Arma configurada: id=%s fallback_damage=%s components=%s visual_offset=%s hitbox_offset=%s attack_areas=%s cooldown=%s" % [
			weapon_source_id,
			str(base_damage),
			_get_component_debug_string(),
			str(attack_visual_offset),
			str(attack_hitbox_offset),
			_get_attack_area_debug_string(),
			str(cooldown_seconds)
		],
		"GaiaInitialWeaponController",
		{
			"weapon_id": weapon_source_id,
			"fallback_damage": base_damage,
			"components": _get_component_debug_string(),
			"visual_offset": attack_visual_offset,
			"hitbox_offset": attack_hitbox_offset,
			"attack_areas": _get_attack_area_debug_string(),
			"cooldown_seconds": cooldown_seconds
		}
	)

## Retorna dano bruto total atual, considerando componentes compostos.
func _get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return base_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

## Retorna componentes de dano em formato compacto para logs.
func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(base_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [
			component.damage_type,
			str(component.amount)
		])

	return ", ".join(parts)

## Retorna áreas ofensivas ativas em formato compacto para logs.
func _get_attack_area_debug_string() -> String:
	var parts: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if not attack_area.is_valid_definition():
			continue

		parts.append(
			attack_area.get_debug_summary(attack_area_scale_multiplier)
		)

	if parts.is_empty():
		return "none"

	return ", ".join(parts)

## Consulta o runtime state atual da Gaia.
func _get_player_runtime_state() -> PlayerRuntimeState:
	if player_controller == null:
		return null

	if not player_controller.has_method("get_runtime_state"):
		return null

	var runtime_state_variant: Variant = player_controller.call(
		"get_runtime_state"
	)

	if runtime_state_variant is PlayerRuntimeState:
		return runtime_state_variant as PlayerRuntimeState

	return null

## Localiza o controller da Gaia pelo parent chain ou pelo grupo player.
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

## Localiza o root onde os visuais temporários da arma são instanciados.
func _resolve_attack_visual_root() -> Node2D:
	if attack_visual_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_visual_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackVisualRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Localiza o root onde as hitboxes temporárias são instanciadas.
func _resolve_attack_hitbox_root() -> Node2D:
	if attack_hitbox_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_hitbox_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackHitboxRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Retorna a posição mundial atual da Gaia.
func _get_player_global_position() -> Vector2:
	if player_controller is Node2D:
		var player_node: Node2D = player_controller as Node2D

		return player_node.global_position

	return Vector2.ZERO

## Recebe um upgrade encaminhado pelo PlayerController.
##
## O retorno booleano é obrigatório:
## - true: o upgrade foi aplicado;
## - false: nenhuma alteração foi realizada.
func apply_run_upgrade(upgrade: UpgradeDefinition) -> bool:
	if upgrade == null:
		return false

	match upgrade.upgrade_type:
		UpgradeTypes.WEAPON_DAMAGE_FLAT:
			return _apply_damage_flat_upgrade(
				upgrade.id,
				upgrade.value_int
			)

		UpgradeTypes.WEAPON_COOLDOWN_PERCENT:
			return _apply_cooldown_percent_upgrade(
				upgrade.id,
				upgrade.value_float
			)

		UpgradeTypes.WEAPON_PHYSICAL_DAMAGE_FLAT:
			return _apply_component_damage_flat_upgrade(
				upgrade.id,
				DamageTypes.PHYSICAL,
				upgrade.value_int
			)

		UpgradeTypes.WEAPON_MAGICAL_DAMAGE_FLAT:
			return _apply_component_damage_flat_upgrade(
				upgrade.id,
				DamageTypes.MAGICAL,
				upgrade.value_int
			)

		UpgradeTypes.WEAPON_ATTACK_AREA_SCALE_PERCENT:
			return _apply_attack_area_scale_percent_upgrade(
				upgrade.id,
				upgrade.value_float
			)

		UpgradeTypes.WEAPON_HITBOX_LIFETIME_PERCENT:
			return _apply_hitbox_lifetime_percent_upgrade(
				upgrade.id,
				upgrade.value_float
			)

		_:
			push_warning(
				"[GaiaInitialWeaponController] Upgrade não suportado pela arma: %s"
				% upgrade.id
			)

			return false

## Aumenta o dano geral da arma.
##
## Na regra provisória atual, armas compostas recebem o valor
## em cada componente existente.
func _apply_damage_flat_upgrade(
	upgrade_id: String,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if damage_components.is_empty():
		base_damage += amount

		DeveloperAuditLogger.log_upgrade(
			"Dano fallback aplicado: +%s | base_damage=%s" % [
				str(amount),
				str(base_damage)
			],
			"GaiaInitialWeaponController",
			{
				"upgrade_id": upgrade_id,
				"weapon_id": weapon_source_id,
				"base_damage": base_damage,
				"mode": "fallback"
			}
		)

		return true

	var applied_count: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		component.amount += amount
		applied_count += 1

	if applied_count <= 0:
		return false

	DeveloperAuditLogger.log_upgrade(
		"Dano geral aplicado em todos os componentes: +%s | components=%s" % [
			str(amount),
			_get_component_debug_string()
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"amount_per_component": amount,
			"applied_count": applied_count,
			"components": _get_component_debug_string()
		}
	)

	return true

## Reduz percentualmente o cooldown atual da arma.
func _apply_cooldown_percent_upgrade(
	upgrade_id: String,
	percent: float
) -> bool:
	if percent <= 0.0:
		return false

	var previous_cooldown_seconds: float = cooldown_seconds
	var multiplier: float = max(0.05, 1.0 - (percent * 0.01))
	var new_cooldown_seconds: float = max(
		0.15,
		cooldown_seconds * multiplier
	)

	if is_equal_approx(previous_cooldown_seconds, new_cooldown_seconds):
		return false

	cooldown_seconds = new_cooldown_seconds
	cooldown_timer = min(cooldown_timer, cooldown_seconds)

	_emit_cooldown_update()

	DeveloperAuditLogger.log_upgrade(
		"Cooldown aplicado: -%s%% | cooldown=%s" % [
			str(percent),
			str(cooldown_seconds)
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"percent": percent,
			"cooldown_seconds": cooldown_seconds
		}
	)

	return true

## Aumenta somente componentes do tipo solicitado.
func _apply_component_damage_flat_upgrade(
	upgrade_id: String,
	damage_type_to_match: String,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if damage_components.is_empty():
		return false

	var applied_count: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		if component.damage_type != damage_type_to_match:
			continue

		component.amount += amount
		applied_count += 1

	if applied_count <= 0:
		return false

	DeveloperAuditLogger.log_upgrade(
		"Dano %s aplicado: +%s | components=%s" % [
			damage_type_to_match,
			str(amount),
			_get_component_debug_string()
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"damage_type": damage_type_to_match,
			"amount": amount,
			"components": _get_component_debug_string()
		}
	)

	return true

## Aumenta uniformemente todas as áreas ofensivas da arma.
func _apply_attack_area_scale_percent_upgrade(
	upgrade_id: String,
	percent: float
) -> bool:
	if percent <= 0.0:
		return false

	if attack_areas.is_empty():
		return false

	var multiplier: float = 1.0 + (percent * 0.01)

	attack_area_scale_multiplier *= multiplier

	DeveloperAuditLogger.log_upgrade(
		"Escala da área de ataque aplicada: +%s%% | scale=%s | areas=%s" % [
			str(percent),
			str(attack_area_scale_multiplier),
			_get_attack_area_debug_string()
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"percent": percent,
			"attack_area_scale_multiplier": attack_area_scale_multiplier,
			"attack_areas": _get_attack_area_debug_string()
		}
	)

	return true

## Aumenta percentualmente o tempo ativo da hitbox.
func _apply_hitbox_lifetime_percent_upgrade(
	upgrade_id: String,
	percent: float
) -> bool:
	if percent <= 0.0:
		return false

	var previous_lifetime: float = attack_hitbox_lifetime
	var multiplier: float = 1.0 + (percent * 0.01)
	var new_lifetime: float = min(
		0.60,
		attack_hitbox_lifetime * multiplier
	)

	if is_equal_approx(previous_lifetime, new_lifetime):
		return false

	attack_hitbox_lifetime = new_lifetime

	DeveloperAuditLogger.log_upgrade(
		"Duração da hitbox aplicada: +%s%% | lifetime=%s" % [
			str(percent),
			str(attack_hitbox_lifetime)
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"percent": percent,
			"hitbox_lifetime": attack_hitbox_lifetime
		}
	)

	return true
	
## Calcula o delay inicial antes do primeiro ataque automático.
func _get_initial_attack_delay() -> float:
	if initial_attack_delay_seconds > 0.0:
		return initial_attack_delay_seconds

	return cooldown_seconds

## Emite o progresso atual de cooldown para HUD e ferramentas técnicas.
func _emit_cooldown_update() -> void:
	if not emit_cooldown_updates:
		return

	var progress_ratio: float = 1.0

	if cooldown_seconds > 0.0:
		progress_ratio = 1.0 - clamp(
			cooldown_timer / cooldown_seconds,
			0.0,
			1.0
		)

	GameEvents.weapon_cooldown_changed.emit(
		weapon_source_id,
		cooldown_timer,
		cooldown_seconds,
		progress_ratio
	)
