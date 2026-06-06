## Controller principal da Gaia/player durante a run.
##
## Responsabilidades:
## - inicializar a Queen a partir de QueenDefinition;
## - ler InputManager e aplicar movimento;
## - controlar dash configurável por QueenDashDefinition;
## - configurar PlayerHurtbox;
## - receber dano via arquitetura Hitbox/Hurtbox;
## - controlar invulnerabilidade, morte e feedback visual;
## - aplicar upgrades de player e encaminhar upgrades de arma;
## - fornecer dados para DebugOverlay e outros sistemas técnicos.
##
## Importante:
## Este script executa regras de gameplay. A camada Spine/visual apenas representa
## os estados decididos aqui.
extends CharacterBody2D
class_name PlayerController

@export var queen_definition: QueenDefinition
@export var runtime_state: PlayerRuntimeState
@export var visual_controller_path: NodePath
@export var draw_debug_aim: bool = false
@export var debug_aim_line_length: float = 96.0
@export var base_defense_percent: float = 0.0

## If enabled, Gaia's body is blocked by enemy bodies (EnemyBody layer).
## Keep it OFF for hordes: with many enemies the physics depenetration pushes/ejects
## Gaia. Enemies still detect her and slide around (player_body_slide) either way.
@export var collide_with_enemy_bodies: bool = false


## Configurações runtime do dash da Gaia/player.
@export_group("Dash")
@export var dash_impact_area_path: NodePath
@export var dash_disable_enemy_body_collision: bool = true
@export_range(1, 32, 1) var enemy_body_collision_layer_number: int = 3
@export_range(0.0, 1.0, 0.05) var dash_lateral_control_strength: float = 0.35
@export var dash_lateral_control_max_speed: float = 120.0

@onready var visual_controller: Node = _resolve_visual_controller()
@onready var player_hurtbox: HurtboxComponent = (
	get_node_or_null("PlayerHurtbox") as HurtboxComponent
)

@onready var dash_impact_area: PlayerDashImpactArea = (
	_resolve_dash_impact_area()
)


## Feedback visual e invulnerabilidade após dano recebido.
@export_group("Damage Feedback")
@export var enable_hit_invincibility: bool = true
@export var invincibility_duration_after_hit: float = 0.5
@export var play_visual_damage_flash: bool = true

var dash_definition: QueenDashDefinition = null
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var active_dash_direction: Vector2 = Vector2.ZERO
var active_dash_speed: float = 0.0
var active_dash_animation_time_scale: float = 1.0
var is_dash_active: bool = false
var collision_mask_before_dash: int = 0
var has_collision_mask_before_dash: bool = false
var dash_distance_multiplier: float = 1.0
var dash_duration_multiplier: float = 1.0
var dash_impact_area_scale_multiplier: float = 1.0


## Inicializa runtime da Gaia, aplica QueenDefinition, configura hurtbox/dash e resolve referências
## visuais.
func _ready() -> void:
	add_to_group("player")

	if runtime_state == null:
		runtime_state = PlayerRuntimeState.new()

	if queen_definition != null:
		runtime_state.setup_from_queen_definition(queen_definition)
	else:
		push_warning("[PlayerController] queen_definition não configurada.")

	runtime_state.defense_percent = clamp(base_defense_percent, 0.0, 95.0)

	_apply_dash_definition()
	_configure_dash_impact_area()

	_configure_player_hurtbox()
	_configure_enemy_body_collision()

	if visual_controller == null:
		push_warning("[PlayerController] visual_controller não encontrado. Verifique visual_controller_path.")

	_update_visual_state()
	_queue_debug_redraw()


## Atualiza input, dash, invulnerabilidade, movimento físico e estado visual a cada frame físico.
func _physics_process(_delta: float) -> void:
	_update_invincibility(_delta)
	_update_dash_cooldown(_delta)

	if runtime_state == null:
		return

	InputManager.update_input_for_player(global_position)

	var move_direction: Vector2 = InputManager.get_move_direction()
	var aim_direction: Vector2 = InputManager.get_aim_direction()

	if not runtime_state.is_alive:
		_cancel_active_dash()
		runtime_state.apply_input(Vector2.ZERO, aim_direction)
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		_queue_debug_redraw()
		return

	if is_dash_active:
		_update_active_dash(_delta, move_direction, aim_direction)
		_update_visual_state()
		_queue_debug_redraw()
		return

	if _should_start_dash():
		_start_dash(move_direction, aim_direction)
		_update_visual_state()
		_queue_debug_redraw()
		return

	runtime_state.apply_input(move_direction, aim_direction)

	velocity = runtime_state.move_direction * runtime_state.move_speed
	move_and_slide()

	_update_visual_state()
	_queue_debug_redraw()


## Reagenda o _draw apenas quando a mira de debug está ligada.
##
# Evita marcar o canvas como "dirty" a cada frame quando o debug está desligado.
func _queue_debug_redraw() -> void:
	if draw_debug_aim:
		queue_redraw()

## Desenha linha técnica de mira quando o debug visual está habilitado.
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


## Recebe DamagePayload vindo da PlayerHurtbox e aplica defesa, invulnerabilidade, feedback e
## morte.
func receive_damage(payload: DamagePayload) -> int:
	if _should_ignore_damage_during_dash():
		return 0
		
	if runtime_state == null:
		return 0

	if payload == null:
		return 0

	if not payload.is_valid_payload():
		return 0

	if not runtime_state.is_alive:
		return 0

	if enable_hit_invincibility and runtime_state.is_invincible:
		return 0

	var raw_total: int = payload.get_total_raw_damage()

	var final_damage: int = DamageResolver.calculate_received_damage(
		raw_total,
		runtime_state.defense_percent,
		payload.can_be_reduced_by_defense
	)

	runtime_state.apply_damage(final_damage, payload.source_id)

	if final_damage > 0:
		_start_hit_invincibility()
		_play_damage_feedback()

	GameEvents.player_damaged.emit(
		raw_total,
		final_damage,
		runtime_state.current_hp,
		runtime_state.max_hp,
		payload.source_id
	)

	DeveloperAuditLogger.log_combat(
		"Dano recebido: raw_total=%s final=%s HP=%s/%s fonte=%s" % [
			str(raw_total),
			str(final_damage),
			str(runtime_state.current_hp),
			str(runtime_state.max_hp),
			payload.source_id
		],
		"PlayerController",
		{
			"queen_id": runtime_state.queen_id,
			"raw_total": raw_total,
			"final_damage": final_damage,
			"current_hp": runtime_state.current_hp,
			"max_hp": runtime_state.max_hp,
			"source_id": payload.source_id,
			"invincibility_started": final_damage > 0 and enable_hit_invincibility
		}
	)

	if not runtime_state.is_alive:
		if player_hurtbox != null:
			player_hurtbox.set_hurtbox_active(false)

		GameEvents.player_died.emit(payload.source_id)

		DeveloperAuditLogger.log_combat(
			"Gaia morreu. causa=%s" % payload.source_id,
			"PlayerController",
			{
				"queen_id": runtime_state.queen_id,
				"source_id": payload.source_id
			}
		)

	_update_visual_state()
	_queue_debug_redraw()

	return final_damage


## Verifica se o dano deve ser ignorado por causa da invulnerabilidade opcional do dash.
func _should_ignore_damage_during_dash() -> bool:
	if runtime_state == null:
		return false

	if not runtime_state.is_dashing:
		return false

	if dash_definition == null:
		return false

	return dash_definition.ignore_damage_while_dashing


## Atualiza o cooldown próprio do dash.
func _update_dash_cooldown(delta: float) -> void:
	if dash_cooldown_timer <= 0.0:
		dash_cooldown_timer = 0.0
		return

	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)


## Decide se o dash pode iniciar neste frame com base em input, cooldown, vida e configuração.
func _should_start_dash() -> bool:
	if dash_definition == null:
		return false

	if not dash_definition.dash_enabled:
		return false

	if dash_cooldown_timer > 0.0:
		return false

	if is_dash_active:
		return false

	return InputManager.was_dash_just_pressed()


## Inicializa estado do dash, velocidade ativa, animação, impacto, colisão temporária e regras de
## arma.
func _start_dash(move_direction: Vector2, aim_direction: Vector2) -> void:
	if dash_definition == null:
		return

	var dash_direction: Vector2 = _resolve_dash_direction(
		move_direction,
		aim_direction
	)

	if dash_direction.length() <= 0.001:
		return

	var effective_dash_duration: float = _get_effective_dash_duration_seconds()
	var effective_dash_distance: float = _get_effective_dash_distance_pixels()

	is_dash_active = true
	_apply_dash_collision_mode(true)

	active_dash_direction = dash_direction.normalized()
	dash_timer = effective_dash_duration
	dash_cooldown_timer = max(0.0, dash_definition.dash_cooldown_seconds)
	active_dash_speed = effective_dash_distance / max(0.01, dash_timer)
	active_dash_animation_time_scale = _get_dash_animation_time_scale(effective_dash_duration)

	runtime_state.start_dash(
		active_dash_direction,
		aim_direction,
		active_dash_animation_time_scale
	)

	if dash_impact_area != null:
		dash_impact_area.activate_for_dash(active_dash_direction)

	_update_visual_state()
	

## Atualiza movimento e controle lateral enquanto o dash está ativo.
func _update_active_dash(
	delta: float,
	move_direction: Vector2,
	aim_direction: Vector2
) -> void:
	if dash_definition == null:
		_finish_dash(move_direction, aim_direction)
		return

	dash_timer -= delta

	runtime_state.update_dash(
		active_dash_direction,
		aim_direction,
		active_dash_animation_time_scale
	)

	var dash_velocity: Vector2 = active_dash_direction * active_dash_speed
	var lateral_velocity: Vector2 = _get_dash_lateral_control_velocity(move_direction)

	velocity = dash_velocity + lateral_velocity
	move_and_slide()

	if dash_timer <= 0.0:
		_finish_dash(move_direction, aim_direction)
		

## Finaliza o dash normalmente e restaura colisão/impacto/regras temporárias.
func _finish_dash(move_direction: Vector2, aim_direction: Vector2) -> void:
	is_dash_active = false
	dash_timer = 0.0
	active_dash_direction = Vector2.ZERO
	active_dash_speed = 0.0
	active_dash_animation_time_scale = 1.0

	_apply_dash_collision_mode(false)

	if dash_impact_area != null:
		dash_impact_area.deactivate()

	runtime_state.finish_dash(move_direction, aim_direction)
	

## Cancela dash ativo por interrupção ou encerramento da run, restaurando estado seguro.
func _cancel_active_dash() -> void:
	is_dash_active = false
	dash_timer = 0.0
	active_dash_direction = Vector2.ZERO
	active_dash_speed = 0.0
	active_dash_animation_time_scale = 1.0

	_apply_dash_collision_mode(false)

	if dash_impact_area != null:
		dash_impact_area.deactivate()

	if runtime_state != null:
		runtime_state.is_dashing = false
		runtime_state.dash_direction = Vector2.ZERO
		runtime_state.dash_animation_time_scale = 1.0


## Resolve a direção usada pelo dash com fallback para movimento, mira ou direção padrão.
func _resolve_dash_direction(
	move_direction: Vector2,
	aim_direction: Vector2
) -> Vector2:
	if move_direction.length() > 0.001:
		return move_direction.normalized()

	if runtime_state != null and runtime_state.move_direction.length() > 0.001:
		return runtime_state.move_direction.normalized()

	if aim_direction.length() > 0.001:
		return aim_direction.normalized()

	if runtime_state != null and runtime_state.last_valid_aim_direction.length() > 0.001:
		return runtime_state.last_valid_aim_direction.normalized()

	return Vector2.RIGHT


## Configura PlayerHurtbox a partir das hurtbox_areas da QueenDefinition.
func _configure_player_hurtbox() -> void:
	if player_hurtbox == null:
		player_hurtbox = get_node_or_null("PlayerHurtbox") as HurtboxComponent

	if player_hurtbox == null:
		push_warning("[PlayerController] PlayerHurtbox não encontrada.")
		return

	if queen_definition == null:
		player_hurtbox.set_hurtbox_active(false)
		return

	if not queen_definition.has_valid_hurtbox_areas():
		player_hurtbox.set_hurtbox_active(false)
		push_warning("[PlayerController] Queen sem hurtbox válida: %s" % queen_definition.id)
		return

	player_hurtbox.setup(
		queen_definition.hurtbox_areas,
		self
	)


## Envia estado, direção e dados de dash para o controller visual da Gaia.
func _update_visual_state() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	if visual_controller.has_method("apply_runtime_state"):
		visual_controller.call("apply_runtime_state", runtime_state)


## Localiza o controller visual configurado ou disponível na hierarquia.
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


## Localiza a área de impacto do dash usada pelo PlayerController.
func _resolve_dash_impact_area() -> PlayerDashImpactArea:
	if dash_impact_area_path != NodePath():
		var configured_area: Node = get_node_or_null(dash_impact_area_path)

		if configured_area is PlayerDashImpactArea:
			return configured_area as PlayerDashImpactArea

	var direct_area: Node = get_node_or_null("DashImpactArea")

	if direct_area is PlayerDashImpactArea:
		return direct_area as PlayerDashImpactArea

	return _find_first_dash_impact_area(self)


## Busca recursivamente a primeira PlayerDashImpactArea abaixo de um node.
func _find_first_dash_impact_area(root: Node) -> PlayerDashImpactArea:
	if root == null:
		return null

	if root is PlayerDashImpactArea:
		return root as PlayerDashImpactArea

	for child: Node in root.get_children():
		var found: PlayerDashImpactArea = _find_first_dash_impact_area(child)

		if found != null:
			return found

	return null


## Busca recursivamente um node que possua determinado método.
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


## Aplica upgrades de player ou encaminha upgrades de arma para os controllers adequados.
func apply_run_upgrade(upgrade: UpgradeDefinition) -> bool:
	if upgrade == null:
		return false

	if runtime_state == null:
		return false

	match upgrade.upgrade_type:
		UpgradeTypes.PLAYER_MOVE_SPEED_PERCENT:
			if upgrade.value_float <= 0.0:
				push_warning("[PlayerController] Upgrade de velocidade sem valor válido: %s" % upgrade.id)
				return false

			var move_multiplier: float = 1.0 + (upgrade.value_float * 0.01)
			runtime_state.move_speed *= move_multiplier

			DeveloperAuditLogger.log_upgrade(
				"Velocidade aplicada: +%s%% | move_speed=%s" % [
					str(upgrade.value_float),
					str(runtime_state.move_speed)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"percent": upgrade.value_float,
					"move_speed": runtime_state.move_speed
				}
			)

		UpgradeTypes.PLAYER_MAX_HP_FLAT:
			var hp_gain: int = max(0, upgrade.value_int)

			if hp_gain <= 0:
				push_warning("[PlayerController] Upgrade de HP sem valor válido: %s" % upgrade.id)
				return false

			runtime_state.max_hp += hp_gain
			runtime_state.heal(hp_gain)

			DeveloperAuditLogger.log_upgrade(
				"HP máximo aplicado: +%s | HP=%s/%s" % [
					str(hp_gain),
					str(runtime_state.current_hp),
					str(runtime_state.max_hp)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"hp_gain": hp_gain,
					"current_hp": runtime_state.current_hp,
					"max_hp": runtime_state.max_hp
				}
			)

		UpgradeTypes.PLAYER_DEFENSE_PERCENT:
			var defense_gain: float = max(0.0, upgrade.value_float)

			if defense_gain <= 0.0:
				push_warning("[PlayerController] Upgrade de defesa sem valor válido: %s" % upgrade.id)
				return false

			var previous_defense_percent: float = runtime_state.defense_percent
			var new_defense_percent: float = clamp(
				runtime_state.defense_percent + defense_gain,
				0.0,
				95.0
			)

			if is_equal_approx(previous_defense_percent, new_defense_percent):
				push_warning("[PlayerController] Defesa já está no limite máximo para upgrade: %s" % upgrade.id)
				return false

			runtime_state.defense_percent = new_defense_percent

			DeveloperAuditLogger.log_upgrade(
				"Defesa aplicada: +%s%% | defense=%s%%" % [
					str(defense_gain),
					str(runtime_state.defense_percent)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"defense_gain": defense_gain,
					"defense_percent": runtime_state.defense_percent
				}
			)

		UpgradeTypes.PLAYER_HEAL_FLAT:
			var heal_amount: int = max(0, upgrade.value_int)

			if heal_amount <= 0:
				push_warning("[PlayerController] Upgrade de cura sem valor válido: %s" % upgrade.id)
				return false

			runtime_state.heal(heal_amount)

			DeveloperAuditLogger.log_upgrade(
				"Cura aplicada: +%s | HP=%s/%s" % [
					str(heal_amount),
					str(runtime_state.current_hp),
					str(runtime_state.max_hp)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"heal_amount": heal_amount,
					"current_hp": runtime_state.current_hp,
					"max_hp": runtime_state.max_hp
				}
			)

		UpgradeTypes.COIN_MAGNET_RADIUS_PERCENT:
			var magnet_bonus: float = max(0.0, upgrade.value_float)

			if magnet_bonus <= 0.0:
				push_warning("[PlayerController] Upgrade de magnetismo sem valor válido: %s" % upgrade.id)
				return false

			runtime_state.coin_magnet_radius_multiplier += magnet_bonus * 0.01

			DeveloperAuditLogger.log_upgrade(
				"Magnetismo aplicado: +%s%% | multiplier=%s" % [
					str(magnet_bonus),
					str(runtime_state.coin_magnet_radius_multiplier)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"percent": magnet_bonus,
					"multiplier": runtime_state.coin_magnet_radius_multiplier
				}
			)

		UpgradeTypes.COIN_COLLECT_RADIUS_PERCENT:
			var collect_bonus: float = max(0.0, upgrade.value_float)

			if collect_bonus <= 0.0:
				push_warning("[PlayerController] Upgrade de coleta sem valor válido: %s" % upgrade.id)
				return false

			runtime_state.coin_collect_radius_multiplier += collect_bonus * 0.01

			DeveloperAuditLogger.log_upgrade(
				"Raio de coleta aplicado: +%s%% | multiplier=%s" % [
					str(collect_bonus),
					str(runtime_state.coin_collect_radius_multiplier)
				],
				"PlayerController",
				{
					"upgrade_id": upgrade.id,
					"percent": collect_bonus,
					"multiplier": runtime_state.coin_collect_radius_multiplier
				}
			)
		
		UpgradeTypes.PLAYER_DASH_DISTANCE_PERCENT:
			apply_dash_distance_percent(upgrade.value_float)
			return true

		UpgradeTypes.PLAYER_DASH_SPEED_PERCENT:
			apply_dash_speed_percent(upgrade.value_float)
			return true

		UpgradeTypes.PLAYER_DASH_IMPACT_AREA_SCALE_PERCENT:
			apply_dash_impact_area_scale_percent(upgrade.value_float)
			return true

		_:
			if not UpgradeTypes.is_weapon_upgrade(upgrade.upgrade_type):
				push_warning("[PlayerController] Tipo de upgrade não suportado: %s" % upgrade.upgrade_type)
				return false

			if not _forward_upgrade_to_weapons(upgrade):
				return false

	_update_visual_state()
	_queue_debug_redraw()

	return true


## Encaminha upgrade para armas ativas quando o tipo pertence ao grupo de arma.
func _forward_upgrade_to_weapons(upgrade: UpgradeDefinition) -> bool:
	var weapon_nodes: Array[Node] = get_tree().get_nodes_in_group("player_weapon")
	var applied_count: int = 0

	for weapon_node: Node in weapon_nodes:
		if not weapon_node.has_method("apply_run_upgrade"):
			continue

		var applied_variant: Variant = weapon_node.call("apply_run_upgrade", upgrade)

		if applied_variant is bool and bool(applied_variant):
			applied_count += 1

	if applied_count <= 0:
		push_warning("[PlayerController] Nenhuma arma recebeu o upgrade: %s" % upgrade.id)
		return false

	return true


## Expõe o PlayerRuntimeState atual para outros sistemas.
func get_runtime_state() -> PlayerRuntimeState:
	return runtime_state


## Retorna snapshot técnico do estado da Gaia para DebugOverlay/ferramentas.
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
		"has_dash_definition": dash_definition != null,
		"is_dash_active": is_dash_active,
		"dash_timer": dash_timer,
		"dash_cooldown_timer": dash_cooldown_timer,
		"active_dash_direction": active_dash_direction,
		"has_dash_impact_area": dash_impact_area != null,
		"has_player_hurtbox": player_hurtbox != null,
		"current_gameplay_state": runtime_state.current_gameplay_state,
		"current_visual_state": runtime_state.current_visual_state,
		"global_position": global_position,
		"total_damage_taken": runtime_state.total_damage_taken,
		"last_damage_taken": runtime_state.last_damage_taken,
		"last_damage_source_id": runtime_state.last_damage_source_id,
		"death_cause": runtime_state.death_cause,
		"coin_magnet_radius_multiplier": runtime_state.coin_magnet_radius_multiplier,
		"coin_collect_radius_multiplier": runtime_state.coin_collect_radius_multiplier
	}


## Retorna modificadores de magnetismo/coleta usados por moedas.
func get_drop_collection_modifiers() -> Dictionary:
	if runtime_state == null:
		return {
			"coin_magnet_radius_multiplier": 1.0,
			"coin_collect_radius_multiplier": 1.0
		}

	return {
		"coin_magnet_radius_multiplier": runtime_state.coin_magnet_radius_multiplier,
		"coin_collect_radius_multiplier": runtime_state.coin_collect_radius_multiplier
	}


## Atualiza temporizador de invulnerabilidade pós-dano.
func _update_invincibility(delta: float) -> void:
	if runtime_state == null:
		return

	if not runtime_state.is_invincible:
		return

	runtime_state.invincibility_timer -= delta

	if runtime_state.invincibility_timer <= 0.0:
		runtime_state.invincibility_timer = 0.0
		runtime_state.is_invincible = false


## Inicia invulnerabilidade temporária após dano recebido.
func _start_hit_invincibility() -> void:
	if runtime_state == null:
		return

	if not enable_hit_invincibility:
		return

	if invincibility_duration_after_hit <= 0.0:
		runtime_state.is_invincible = false
		runtime_state.invincibility_timer = 0.0
		return

	runtime_state.is_invincible = true
	runtime_state.invincibility_timer = invincibility_duration_after_hit


## Dispara feedback visual de dano na Gaia quando disponível.
func _play_damage_feedback() -> void:
	if not play_visual_damage_flash:
		return

	if visual_controller == null:
		return

	if visual_controller.has_method("play_damage_flash"):
		visual_controller.call("play_damage_flash")


## Calcula contribuição lateral permitida durante dash.
func _get_dash_lateral_control_velocity(move_direction: Vector2) -> Vector2:
	if move_direction.length() <= 0.001:
		return Vector2.ZERO

	if active_dash_direction.length() <= 0.001:
		return Vector2.ZERO

	if dash_lateral_control_strength <= 0.0:
		return Vector2.ZERO

	var dash_forward: Vector2 = active_dash_direction.normalized()
	var dash_lateral: Vector2 = Vector2(
		-dash_forward.y,
		dash_forward.x
	).normalized()

	var lateral_input_amount: float = move_direction.dot(dash_lateral)

	if abs(lateral_input_amount) <= 0.001:
		return Vector2.ZERO

	var lateral_speed: float = min(
		dash_lateral_control_max_speed,
		active_dash_speed * dash_lateral_control_strength
	)

	return dash_lateral * lateral_input_amount * lateral_speed


## Copia QueenDashDefinition para o estado runtime do player.
func _apply_dash_definition() -> void:
	dash_definition = null
	dash_impact_area_scale_multiplier = 1.0

	if queen_definition == null:
		return

	if queen_definition.dash_definition == null:
		return

	if not queen_definition.dash_definition.is_valid_definition():
		push_warning("[PlayerController] DashDefinition inválida para Queen: %s" % queen_definition.id)
		return

	dash_definition = queen_definition.dash_definition
	dash_impact_area_scale_multiplier = max(
		0.01,
		dash_definition.impact_area_scale_multiplier
	)


## Configura PlayerDashImpactArea com os dados atuais do dash.
func _configure_dash_impact_area() -> void:
	if dash_impact_area == null:
		dash_impact_area = _resolve_dash_impact_area()

	if dash_impact_area == null:
		return

	if dash_definition == null:
		dash_impact_area.deactivate()
		return

	dash_impact_area.setup(
		dash_definition,
		self,
		dash_definition.impact_source_id,
		dash_impact_area_scale_multiplier
	)


## Calcula distância efetiva do dash considerando multiplicadores de upgrade.
func _get_effective_dash_distance_pixels() -> float:
	if dash_definition == null:
		return 0.0

	return max(
		0.0,
		dash_definition.dash_distance_pixels * dash_distance_multiplier
	)


## Calcula duração efetiva do dash considerando multiplicadores de velocidade/duração.
func _get_effective_dash_duration_seconds() -> float:
	if dash_definition == null:
		return 0.01

	return max(
		0.01,
		dash_definition.dash_duration_seconds * dash_duration_multiplier
	)


## Calcula time scale da animação de dash para caber na duração configurada.
func _get_dash_animation_time_scale(effective_dash_duration: float) -> float:
	if dash_definition == null:
		return 1.0

	if not dash_definition.match_animation_speed_to_dash_duration:
		return 1.0

	if dash_definition.dash_animation_source_duration_seconds <= 0.0:
		return 1.0

	return max(
		0.01,
		dash_definition.dash_animation_source_duration_seconds / max(0.01, effective_dash_duration)
	)


## Configura se o corpo da Gaia colide com EnemyBody.
##
# Por padrão a Gaia atravessa os inimigos para nunca ser empurrada/teleportada por
# aglomerados; os inimigos ainda a detectam e escorregam ao redor (player_body_slide).
func _configure_enemy_body_collision() -> void:
	set_collision_mask_value(enemy_body_collision_layer_number, collide_with_enemy_bodies)

## Ativa/restaura máscara de colisão para permitir atravessar EnemyBody durante dash.
func _apply_dash_collision_mode(should_enable_dash_mode: bool) -> void:
	if not dash_disable_enemy_body_collision:
		return

	if should_enable_dash_mode:
		if not has_collision_mask_before_dash:
			collision_mask_before_dash = collision_mask
			has_collision_mask_before_dash = true

		set_collision_mask_value(enemy_body_collision_layer_number, false)
		return

	if has_collision_mask_before_dash:
		collision_mask = collision_mask_before_dash
		has_collision_mask_before_dash = false


## Hook de upgrade: aumenta distância do dash em percentual.
func apply_dash_distance_percent(percent: float) -> void:
	var multiplier: float = 1.0 + max(0.0, percent) * 0.01
	dash_distance_multiplier *= multiplier


## Hook de upgrade: altera velocidade/duração efetiva do dash em percentual.
func apply_dash_speed_percent(percent: float) -> void:
	var multiplier: float = 1.0 + max(0.0, percent) * 0.01

	if multiplier <= 0.0:
		return

	dash_duration_multiplier /= multiplier


## Hook de upgrade: escala área de impacto do dash em percentual.
func apply_dash_impact_area_scale_percent(percent: float) -> void:
	var multiplier: float = 1.0 + max(0.0, percent) * 0.01
	dash_impact_area_scale_multiplier *= multiplier

	if dash_impact_area != null and dash_definition != null:
		dash_impact_area.setup(
			dash_definition,
			self,
			dash_definition.impact_source_id,
			dash_impact_area_scale_multiplier
		)


## Consulta se armas podem atacar durante dash.
func can_weapon_attack_while_dashing() -> bool:
	if dash_definition == null:
		return false

	return dash_definition.allow_weapon_attacks_while_dashing


## Consulta se cooldown da arma deve pausar durante dash.
func should_pause_weapon_cooldown_while_dashing() -> bool:
	if dash_definition == null:
		return true

	return dash_definition.pause_weapon_cooldown_while_dashing


## Consulta se cooldown da arma deve resetar ao iniciar dash.
func should_reset_weapon_cooldown_when_dash_starts() -> bool:
	if dash_definition == null:
		return false

	return dash_definition.reset_weapon_cooldown_when_dash_starts


## Consulta se cooldown da arma deve resetar ao finalizar dash.
func should_reset_weapon_cooldown_when_dash_ends() -> bool:
	if dash_definition == null:
		return true

	return dash_definition.reset_weapon_cooldown_when_dash_ends
