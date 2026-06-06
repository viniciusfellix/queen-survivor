## Controller da arma inicial da Gaia.
##
## Responsabilidades:
## - carregar WeaponDefinition;
## - controlar cooldown automático;
## - disparar ataque na direção de mira;
## - instanciar visual e DirectionalAttackHitbox;
## - copiar componentes de dano e áreas ofensivas para runtime;
## - aplicar upgrades de arma;
## - repassar regras de knockback e escala de área;
## - respeitar regras de dash definidas pela QueenDashDefinition.
##
## Importante:
## O visual do ataque não calcula dano. A regra ofensiva fica na hitbox.
extends Node

## Resource principal de configuração usado para preencher estado runtime.
@export_group("Definition")
@export var weapon_definition: WeaponDefinition

## Cenas instanciadas por este controller.
@export_group("Scenes")
@export_file("*.tscn") var attack_visual_scene_path: String = "res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn"
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

## Containers da cena onde instâncias runtime serão adicionadas.
@export_group("Runtime Roots")
@export var attack_visual_root_path: NodePath
@export var attack_hitbox_root_path: NodePath

## Flags de comportamento geral da arma/sistema.
@export_group("Behaviour")
@export var weapon_enabled: bool = true
@export var attack_on_ready: bool = false
@export var initial_attack_delay_seconds: float = -1.0
@export var emit_cooldown_updates: bool = true

## Configurações e estado de recarga.
@export_group("Cooldown")
@export var cooldown_seconds: float = 2.0

## Configurações do efeito visual do ataque. Não calculam dano.
@export_group("Attack Visual")
@export var attack_visual_offset: float = 86.0
@export var attack_visual_lifetime: float = 0.22
@export var attack_visual_scale: Vector2 = Vector2.ONE

## Configurações da hitbox ofensiva real do ataque.
@export_group("Attack Hitbox")
@export var attack_hitbox_offset: float = 86.0
@export var attack_hitbox_lifetime: float = 0.12
@export var attack_areas: Array[AttackAreaDefinition] = []

## Efeitos aplicados somente depois de um hit válido.
@export_group("On Hit Effects")
@export var hit_knockback_enabled: bool = false
@export var hit_knockback_pixels: float = 0.0
@export var hit_knockback_duration_seconds: float = 0.12

## Configuração de dano simples ou composto.
@export_group("Damage")
@export var base_damage: int = 5
@export var damage_type: String = DamageTypes.PHYSICAL
@export var damage_components: Array[DamageComponentDefinition] = []
@export var weapon_source_id: String = "gaia_initial_weapon"

var cooldown_timer: float = 0.0
var was_player_dashing: bool = false
var attack_area_scale_multiplier: float = 1.0
var player_controller: PlayerController = null
var attack_visual_root: Node2D = null
var attack_hitbox_root: Node2D = null

## Inicializa arma, aplica WeaponDefinition e resolve referências runtime.
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

## Atualiza cooldown, respeita dash/regras da run e dispara automaticamente.
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

	if runtime_state == null or not runtime_state.is_alive:
		return

	if _handle_dash_attack_rules(runtime_state, delta):
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)
	_emit_cooldown_update()

	if cooldown_timer > 0.0:
		return

	if not _can_fire_while_player_state_allows(runtime_state):
		return

	_fire_attack(runtime_state)
	cooldown_timer = cooldown_seconds
	_emit_cooldown_update()

## Dispara manualmente a arma para testes ou futuras mecânicas.
func force_fire() -> void:
	var runtime_state: PlayerRuntimeState = _get_player_runtime_state()

	if runtime_state == null or not runtime_state.is_alive:
		return

	if not _can_fire_while_player_state_allows(runtime_state):
		return

	_fire_attack(runtime_state)
	cooldown_timer = cooldown_seconds
	_emit_cooldown_update()

## Executa disparo completo: visual, hitbox e logs.
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

## Instancia somente o efeito visual do ataque.
func _spawn_attack_visual(direction: Vector2) -> void:
	# Posição final do visual, aplicada já no spawn (antes do add_child).
	var visual_spawn_position: Vector2 = (
		_get_player_global_position() + direction * attack_visual_offset
	)

	# Adquire o visual de ataque do pool (reutiliza visuais já expirados).
	var visual_instance: Node = PoolManager.spawn_path(
		attack_visual_scene_path,
		attack_visual_root,
		visual_spawn_position
	)

	if not visual_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack visual inválido ou não é Node2D.")

		if visual_instance != null:
			PoolManager.despawn(visual_instance)

		return

	var visual_node: Node2D = visual_instance as Node2D

	if visual_node.has_method("setup"):
		visual_node.call(
			"setup",
			direction,
			attack_visual_lifetime,
			attack_visual_scale
		)

## Instancia DirectionalAttackHitbox configurada com dano, áreas e knockback.
func _spawn_attack_hitbox(direction: Vector2) -> void:
	# Posição final da hitbox, aplicada já no spawn (antes do add_child).
	var hitbox_spawn_position: Vector2 = (
		_get_player_global_position() + direction * attack_hitbox_offset
	)

	# Adquire a hitbox de ataque do pool (reutiliza hitboxes já expiradas).
	var hitbox_instance: Node = PoolManager.spawn_path(
		attack_hitbox_scene_path,
		attack_hitbox_root,
		hitbox_spawn_position
	)

	if not hitbox_instance is Node2D:
		push_warning("[GaiaInitialWeaponController] Attack hitbox inválida ou não é Node2D.")

		if hitbox_instance != null:
			PoolManager.despawn(hitbox_instance)

		return

	var hitbox_node: Node2D = hitbox_instance as Node2D

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
			attack_area_scale_multiplier,
			hit_knockback_enabled,
			hit_knockback_pixels,
			hit_knockback_duration_seconds
		)

## Resolve direção de mira usada pelo próximo ataque.
func _resolve_attack_direction(runtime_state: PlayerRuntimeState) -> Vector2:
	var direction: Vector2 = runtime_state.aim_direction

	if direction.length() <= 0.001:
		direction = runtime_state.last_valid_aim_direction

	if direction.length() <= 0.001:
		direction = Vector2.RIGHT

	return direction.normalized()

## Copia dados do WeaponDefinition para estado runtime da arma.
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

	hit_knockback_enabled = weapon_definition.hit_knockback_enabled
	hit_knockback_pixels = max(0.0, weapon_definition.hit_knockback_pixels)
	hit_knockback_duration_seconds = max(
		0.01,
		weapon_definition.hit_knockback_duration_seconds
	)

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
		"Arma configurada: id=%s fallback_damage=%s components=%s visual_offset=%s hitbox_offset=%s attack_areas=%s cooldown=%s knockback=%s/%spx" % [
			weapon_source_id,
			str(base_damage),
			_get_component_debug_string(),
			str(attack_visual_offset),
			str(attack_hitbox_offset),
			_get_attack_area_debug_string(),
			str(cooldown_seconds),
			str(hit_knockback_enabled),
			str(hit_knockback_pixels)
		],
		"GaiaInitialWeaponController",
		{
			"weapon_id": weapon_source_id,
			"fallback_damage": base_damage,
			"components": _get_component_debug_string(),
			"visual_offset": attack_visual_offset,
			"hitbox_offset": attack_hitbox_offset,
			"attack_areas": _get_attack_area_debug_string(),
			"cooldown_seconds": cooldown_seconds,
			"hit_knockback_enabled": hit_knockback_enabled,
			"hit_knockback_pixels": hit_knockback_pixels,
			"hit_knockback_duration_seconds": hit_knockback_duration_seconds
		}
	)

## Soma dano bruto dos componentes ou retorna fallback simples.
func _get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return base_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

## Gera resumo dos componentes atuais de dano.
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

## Gera resumo das áreas ofensivas atuais.
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

## Obtém PlayerRuntimeState do player dono da arma.
func _get_player_runtime_state() -> PlayerRuntimeState:
	if player_controller == null:
		return null

	return player_controller.get_runtime_state()

## Localiza o PlayerController na hierarquia ou grupo player.
func _resolve_player_controller() -> PlayerController:
	var current: Node = self

	while current != null:
		if current is PlayerController:
			return current as PlayerController

		current = current.get_parent()

	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	for player: Node in players:
		if player is PlayerController:
			return player as PlayerController

	return null

## Resolve container para efeitos visuais do ataque.
func _resolve_attack_visual_root() -> Node2D:
	if attack_visual_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_visual_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackVisualRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Resolve container para hitboxes do ataque.
func _resolve_attack_hitbox_root() -> Node2D:
	if attack_hitbox_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_hitbox_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackHitboxRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Retorna posição global do player dono da arma.
func _get_player_global_position() -> Vector2:
	if player_controller is Node2D:
		var player_node: Node2D = player_controller as Node2D

		return player_node.global_position

	return Vector2.ZERO

## Aplica upgrade de arma compatível.
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

## Aplica aumento de dano geral/fallback/componentes.
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

## Reduz cooldown da arma em percentual.
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

## Aumenta apenas componentes de um tipo específico de dano.
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

## Escala áreas ofensivas da arma em percentual.
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

## Aumenta duração ativa da hitbox da arma.
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

## Calcula atraso inicial antes do primeiro ataque.
func _get_initial_attack_delay() -> float:
	if initial_attack_delay_seconds > 0.0:
		return initial_attack_delay_seconds

	return cooldown_seconds

## Emite progresso de cooldown para HUD.
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


## Aplica regras de cooldown/ataque durante transições de dash.
func _handle_dash_attack_rules(
	runtime_state: PlayerRuntimeState,
	delta: float
) -> bool:
	var is_dashing: bool = _is_player_dashing(runtime_state)

	if not is_dashing:
		if was_player_dashing:
			if _should_reset_weapon_cooldown_when_dash_ends():
				cooldown_timer = cooldown_seconds
				_emit_cooldown_update()

		was_player_dashing = false
		return false

	if not was_player_dashing:
		if _should_reset_weapon_cooldown_when_dash_starts():
			cooldown_timer = cooldown_seconds
			_emit_cooldown_update()

	was_player_dashing = true

	if _can_weapon_attack_while_dashing():
		return false

	if _should_pause_weapon_cooldown_while_dashing():
		return true

	cooldown_timer = max(0.0, cooldown_timer - delta)
	_emit_cooldown_update()
	return true


## Verifica se o estado atual do player permite disparar.
func _can_fire_while_player_state_allows(runtime_state: PlayerRuntimeState) -> bool:
	if not _is_player_dashing(runtime_state):
		return true

	return _can_weapon_attack_while_dashing()


## Consulta se o player está em dash.
func _is_player_dashing(runtime_state: PlayerRuntimeState) -> bool:
	if runtime_state == null:
		return false

	return (
		runtime_state.is_dashing
		or runtime_state.current_gameplay_state == GameplayStateTypes.DASHING
	)


## Consulta QueenDashDefinition para saber se arma pode atacar durante dash.
func _can_weapon_attack_while_dashing() -> bool:
	if player_controller != null:
		return player_controller.can_weapon_attack_while_dashing()

	return false


## Consulta se cooldown deve pausar durante dash.
func _should_pause_weapon_cooldown_while_dashing() -> bool:
	if player_controller != null:
		return player_controller.should_pause_weapon_cooldown_while_dashing()

	return true


## Consulta se cooldown deve resetar ao iniciar dash.
func _should_reset_weapon_cooldown_when_dash_starts() -> bool:
	if player_controller != null:
		return player_controller.should_reset_weapon_cooldown_when_dash_starts()

	return false


## Consulta se cooldown deve resetar ao finalizar dash.
func _should_reset_weapon_cooldown_when_dash_ends() -> bool:
	if player_controller != null:
		return player_controller.should_reset_weapon_cooldown_when_dash_ends()

	return true
