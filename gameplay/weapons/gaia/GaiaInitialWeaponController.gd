## Controller da arma inicial direcional da Gaia.
##
## Responsabilidades:
## - carregar valores da `WeaponDefinition`;
## - controlar cooldown automático;
## - utilizar direção de mira da Queen;
## - instanciar visual e hitbox do ataque;
## - manter componentes de dano runtime independentes do resource original;
## - receber upgrades de arma durante a run;
## - emitir atualizações para HUD.
extends Node

## Definition de balanceamento inicial da arma.
@export var weapon_definition: WeaponDefinition

## Cena visual instanciada em cada disparo.
@export_file("*.tscn") var attack_visual_scene_path: String = "res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn"

## Cena da hitbox instanciada em cada disparo.
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

## Caminho opcional para o container dos visuais de ataque.
@export var attack_visual_root_path: NodePath

## Caminho opcional para o container das hitboxes de ataque.
@export var attack_hitbox_root_path: NodePath

## Ativa ou desativa o funcionamento automático da arma.
@export var weapon_enabled: bool = true

## Define se a arma dispara imediatamente ao carregar a cena.
##
## Para gameplay normal, deve permanecer `false`.
@export var attack_on_ready: bool = false

## Delay inicial até o primeiro disparo quando `attack_on_ready` é falso.
##
## Valores menores ou iguais a zero utilizam o cooldown normal da arma.
@export var initial_attack_delay_seconds: float = -1.0

## Define se atualizações de cooldown devem ser emitidas para a HUD.
@export var emit_cooldown_updates: bool = true

## Intervalo runtime atual entre disparos.
@export var cooldown_seconds: float = 2.0

## Distância do player em que o visual do ataque será instanciado.
@export var attack_visual_offset: float = 86.0

## Tempo de existência do visual de ataque.
@export var attack_visual_lifetime: float = 0.22

## Escala aplicada ao visual de ataque instanciado.
@export var attack_visual_scale: Vector2 = Vector2.ONE

## Distância do player em que a hitbox será instanciada.
@export var attack_hitbox_offset: float = 86.0

## Raio atual da hitbox da arma.
@export var attack_hitbox_radius: float = 72.0

## Duração atual da hitbox da arma.
@export var attack_hitbox_lifetime: float = 0.12

## Dano fallback para armas configuradas sem componentes.
@export var base_damage: int = 5

## Tipo do dano fallback.
@export var damage_type: String = DamageTypes.PHYSICAL

## Componentes de dano atuais da arma.
##
## Na arma inicial da Gaia, a lista contém dano físico e dano mágico.
@export var damage_components: Array[DamageComponentDefinition] = []

## ID publicado como fonte dos ataques desta arma.
@export var weapon_source_id: String = "gaia_initial_weapon"

## Tempo restante até a arma poder disparar novamente.
var cooldown_timer: float = 0.0

## Referência do controller da Queen que possui esta arma.
var player_controller: Node = null

## Container dos visuais instanciados.
var attack_visual_root: Node2D = null

## Container das hitboxes instanciadas.
var attack_hitbox_root: Node2D = null

## Inicializa a arma, duplica seus componentes runtime e prepara o cooldown.
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

## Atualiza o cooldown e dispara automaticamente quando a arma está pronta.
##
## A arma não processa disparos durante level-up, morte ou fim da run.
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
		_emit_cooldown_update()

## Dispara manualmente a arma, respeitando bloqueios da run e vida do player.
##
## Útil para testes ou futuras mecânicas específicas.
func force_fire() -> void:
	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	var runtime_state: PlayerRuntimeState = _get_player_runtime_state()

	if runtime_state == null:
		return

	if not runtime_state.is_alive:
		return

	_fire_attack(runtime_state)
	cooldown_timer = cooldown_seconds
	_emit_cooldown_update()

## Executa um disparo completo na direção atual de mira.
##
## O visual e a hitbox são instanciados separadamente,
## permitindo substituir efeitos visuais sem afetar o dano.
func _fire_attack(runtime_state: PlayerRuntimeState) -> void:
	var direction: Vector2 = _resolve_attack_direction(runtime_state)

	_spawn_attack_visual(direction)
	_spawn_attack_hitbox(direction)

	DeveloperAuditLogger.log_combat(
		"Ataque disparado: direction=%s raw_total=%s components=%s" % [
			str(direction),
			str(_get_total_raw_damage()),
			_get_component_debug_string()
		],
		"GaiaInitialWeaponController",
		{
			"direction": direction,
			"raw_total": _get_total_raw_damage(),
			"components": _get_component_debug_string(),
			"weapon_id": weapon_source_id
		}
	)

## Instancia somente a representação visual do ataque.
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

## Instancia a área que verificará impactos contra inimigos.
##
## Componentes atuais são enviados para que cada hitbox tenha
## uma cópia independente do dano daquele disparo.
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

## Resolve a direção utilizada pelo próximo disparo.
##
## Prioridade:
## 1. mira atual;
## 2. última mira válida;
## 3. direção padrão para a direita.
func _resolve_attack_direction(runtime_state: PlayerRuntimeState) -> Vector2:
	var direction: Vector2 = runtime_state.aim_direction

	if direction.length() <= 0.001:
		direction = runtime_state.last_valid_aim_direction

	if direction.length() <= 0.001:
		direction = Vector2.RIGHT

	return direction.normalized()

## Copia valores iniciais da `WeaponDefinition` para o estado runtime da arma.
##
## Os componentes são duplicados profundamente para que upgrades
## não alterem o resource original salvo no projeto.
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

	DeveloperAuditLogger.log_scene(
		"Arma configurada: id=%s fallback_damage=%s components=%s visual_offset=%s hitbox_offset=%s hitbox_radius=%s cooldown=%s" % [
			weapon_source_id,
			str(base_damage),
			_get_component_debug_string(),
			str(attack_visual_offset),
			str(attack_hitbox_offset),
			str(attack_hitbox_radius),
			str(cooldown_seconds)
		],
		"GaiaInitialWeaponController",
		{
			"weapon_id": weapon_source_id,
			"fallback_damage": base_damage,
			"components": _get_component_debug_string(),
			"visual_offset": attack_visual_offset,
			"hitbox_offset": attack_hitbox_offset,
			"hitbox_radius": attack_hitbox_radius,
			"cooldown_seconds": cooldown_seconds
		}
	)

## Soma o dano bruto atual de todos os componentes da arma.
##
## Quando não existem componentes, retorna o dano fallback.
func _get_total_raw_damage() -> int:
	if damage_components.is_empty():
		return base_damage

	var total: int = 0

	for component: DamageComponentDefinition in damage_components:
		if component != null and component.is_valid_component():
			total += component.amount

	return total

## Formata componentes atuais para logs técnicos.
func _get_component_debug_string() -> String:
	if damage_components.is_empty():
		return "%s:%s" % [damage_type, str(base_damage)]

	var parts: Array[String] = []

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		parts.append("%s:%s" % [component.damage_type, str(component.amount)])

	return ", ".join(parts)

## Obtém o estado runtime da Queen proprietária da arma.
func _get_player_runtime_state() -> PlayerRuntimeState:
	if player_controller == null:
		return null

	if not player_controller.has_method("get_runtime_state"):
		return null

	var runtime_state_variant: Variant = player_controller.call("get_runtime_state")

	if runtime_state_variant is PlayerRuntimeState:
		return runtime_state_variant as PlayerRuntimeState

	return null

## Localiza o controller da Queen.
##
## Primeiro percorre a hierarquia ascendente da arma; caso necessário,
## procura uma entidade compatível no grupo global `player`.
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

## Resolve o container onde visuais do ataque serão inseridos.
func _resolve_attack_visual_root() -> Node2D:
	if attack_visual_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_visual_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackVisualRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Resolve o container onde hitboxes do ataque serão inseridas.
func _resolve_attack_hitbox_root() -> Node2D:
	if attack_hitbox_root_path != NodePath():
		var configured_root: Node = get_node_or_null(attack_hitbox_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var sibling_root: Node = get_node_or_null("../AttackHitboxRoot")

	if sibling_root is Node2D:
		return sibling_root as Node2D

	return null

## Retorna a posição mundial atual da Queen proprietária da arma.
func _get_player_global_position() -> Vector2:
	if player_controller is Node2D:
		var player_node: Node2D = player_controller as Node2D
		return player_node.global_position

	return Vector2.ZERO

## Aplica um upgrade compatível com esta arma.
##
## Retorna `true` apenas quando o efeito foi efetivamente registrado.
func apply_run_upgrade(upgrade: UpgradeDefinition) -> bool:
	if upgrade == null:
		return false

	match upgrade.upgrade_type:
		UpgradeTypes.WEAPON_DAMAGE_FLAT:
			return _apply_damage_flat_upgrade(upgrade.id, upgrade.value_int)

		UpgradeTypes.WEAPON_COOLDOWN_PERCENT:
			return _apply_cooldown_percent_upgrade(upgrade.id, upgrade.value_float)

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

		UpgradeTypes.WEAPON_HITBOX_RADIUS_FLAT:
			return _apply_hitbox_radius_flat_upgrade(upgrade.id, upgrade.value_int)

		UpgradeTypes.WEAPON_HITBOX_LIFETIME_PERCENT:
			return _apply_hitbox_lifetime_percent_upgrade(upgrade.id, upgrade.value_float)

		_:
			push_warning("[GaiaInitialWeaponController] Upgrade não suportado pela arma: %s" % upgrade.id)
			return false

## Aumenta o dano geral da arma.
##
## Em armas compostas, o valor atual é adicionado a cada componente.
## Esta decisão foi mantida para validação posterior com o game designer.
func _apply_damage_flat_upgrade(upgrade_id: String, amount: int) -> bool:
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

	for component: DamageComponentDefinition in damage_components:
		if component == null:
			continue

		component.amount += amount

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
			"components": _get_component_debug_string()
		}
	)

	return true

## Reduz percentualmente o cooldown atual da arma.
##
## Mantém um limite mínimo de `0.15` segundo para evitar disparos
## excessivamente rápidos no protótipo.
func _apply_cooldown_percent_upgrade(upgrade_id: String, percent: float) -> bool:
	if percent <= 0.0:
		return false

	var previous_cooldown_seconds: float = cooldown_seconds
	var multiplier: float = max(0.05, 1.0 - (percent * 0.01))
	var new_cooldown_seconds: float = max(0.15, cooldown_seconds * multiplier)

	if is_equal_approx(previous_cooldown_seconds, new_cooldown_seconds):
		push_warning("[GaiaInitialWeaponController] Cooldown já está no limite mínimo para upgrade: %s" % upgrade_id)
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
			"cooldown_seconds": cooldown_seconds,
			"cooldown_timer": cooldown_timer
		}
	)

	return true

## Aumenta apenas componentes de determinado tipo de dano.
##
## Utilizado para melhorias físicas ou mágicas específicas.
func _apply_component_damage_flat_upgrade(
	upgrade_id: String,
	damage_type_to_match: String,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if damage_components.is_empty():
		push_warning(
			"[GaiaInitialWeaponController] Sem componentes para aplicar dano específico: %s"
			% damage_type_to_match
		)
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
		push_warning(
			"[GaiaInitialWeaponController] Nenhum componente encontrado para dano: %s"
			% damage_type_to_match
		)
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
			"applied_count": applied_count,
			"components": _get_component_debug_string()
		}
	)

	return true

## Aumenta diretamente o raio da área de acerto do ataque.
func _apply_hitbox_radius_flat_upgrade(upgrade_id: String, amount: int) -> bool:
	if amount <= 0:
		return false

	attack_hitbox_radius += float(amount)

	DeveloperAuditLogger.log_upgrade(
		"Raio da hitbox aplicado: +%s | radius=%s" % [
			str(amount),
			str(attack_hitbox_radius)
		],
		"GaiaInitialWeaponController",
		{
			"upgrade_id": upgrade_id,
			"weapon_id": weapon_source_id,
			"amount": amount,
			"hitbox_radius": attack_hitbox_radius
		}
	)

	return true

## Aumenta percentualmente o tempo ativo da hitbox.
##
## Mantém limite máximo de `0.60` segundo no protótipo atual.
func _apply_hitbox_lifetime_percent_upgrade(upgrade_id: String, percent: float) -> bool:
	if percent <= 0.0:
		return false

	var previous_lifetime: float = attack_hitbox_lifetime
	var multiplier: float = 1.0 + (percent * 0.01)
	var new_lifetime: float = min(0.60, attack_hitbox_lifetime * multiplier)

	if is_equal_approx(previous_lifetime, new_lifetime):
		push_warning("[GaiaInitialWeaponController] Duração da hitbox já está no limite máximo para upgrade: %s" % upgrade_id)
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

## Retorna o delay utilizado antes do primeiro disparo automático.
func _get_initial_attack_delay() -> float:
	if initial_attack_delay_seconds > 0.0:
		return initial_attack_delay_seconds

	return cooldown_seconds

## Emite para a HUD o progresso atual da recarga da arma.
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
