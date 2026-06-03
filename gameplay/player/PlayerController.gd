## Controller principal da Queen controlada pelo jogador.
##
## Responsabilidades:
## - registrar a entidade no grupo `player`;
## - criar e inicializar seu `PlayerRuntimeState`;
## - ler movimento e mira do `InputManager`;
## - movimentar a personagem;
## - receber dano e aplicar feedback visual;
## - controlar invencibilidade temporária após impacto;
## - aplicar upgrades próprios da Queen;
## - encaminhar upgrades de arma para controllers compatíveis;
## - expor informações para moedas, HUD e ferramentas técnicas.
extends CharacterBody2D

## Dados base da Queen utilizada nesta cena.
@export var queen_definition: QueenDefinition

## Estado mutável da Queen durante a run atual.
@export var runtime_state: PlayerRuntimeState

## Caminho opcional para o controller visual da personagem.
@export var visual_controller_path: NodePath

## Exibe a linha técnica da direção atual de mira.
@export var draw_debug_aim: bool = false

## Comprimento visual da linha técnica de mira.
@export var debug_aim_line_length: float = 96.0

## Defesa percentual inicial aplicada ao começar a run.
##
## Pode ser utilizada em testes e posteriormente ampliada por upgrades.
@export var base_defense_percent: float = 0.0

@export_group("Dash")

## Caminho opcional para a área de impacto do dash.
@export var dash_impact_area_path: NodePath

## Se verdadeiro, a Gaia deixa de colidir fisicamente com EnemyBody durante dash.
##
## Isso permite atravessar grupos de inimigos, enquanto o knockback continua
## sendo aplicado pela DashImpactArea contra EnemyHurtbox.
@export var dash_disable_enemy_body_collision: bool = true

## Layer física corporal dos inimigos.
##
## Oficial atual:
## Layer 3 = EnemyBody.
@export_range(1, 32, 1) var enemy_body_collision_layer_number: int = 3

## Controller visual responsável pelas animações e flash de dano.
@onready var visual_controller: Node = _resolve_visual_controller()

## Hurtbox responsável por receber ataques de inimigos.
@onready var player_hurtbox: HurtboxComponent = (
	get_node_or_null("PlayerHurtbox") as HurtboxComponent
)

## Área ofensiva sem dano usada para aplicar knockback durante dash.
@onready var dash_impact_area: PlayerDashImpactArea = (
	_resolve_dash_impact_area()
)

@export_group("Damage Feedback")

## Ativa a pequena janela de invencibilidade após receber dano.
@export var enable_hit_invincibility: bool = true

## Duração, em segundos, da invencibilidade após impacto.
@export var invincibility_duration_after_hit: float = 0.5

## Define se o visual da Queen pisca ao receber dano.
@export var play_visual_damage_flash: bool = true

## Configuração de dash da Queen atual.
var dash_definition: QueenDashDefinition = null

## Tempo restante do dash ativo.
var dash_timer: float = 0.0

## Tempo restante de cooldown do dash.
var dash_cooldown_timer: float = 0.0

## Direção atual do dash.
var active_dash_direction: Vector2 = Vector2.ZERO

## Velocidade calculada do dash atual.
var active_dash_speed: float = 0.0

## Indica se o PlayerController está executando dash.
var is_dash_active: bool = false

## Máscara de colisão corporal antes do dash.
var collision_mask_before_dash: int = 0

## Indica se existe máscara corporal salva para restaurar.
var has_collision_mask_before_dash: bool = false

## Inicializa a Queen, aplica sua definition e prepara o visual inicial.
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

	if visual_controller == null:
		push_warning("[PlayerController] visual_controller não encontrado. Verifique visual_controller_path.")

	_update_visual_state()
	queue_redraw()

## Executa o ciclo físico da personagem.
##
## Fluxo normal:
## - reduz tempo restante de invencibilidade;
## - reduz cooldown do dash;
## - obtém movimento e mira atuais;
## - executa dash ativo, quando houver;
## - inicia dash quando o input permitir;
## - movimenta normalmente enquanto viva;
## - sincroniza animações e desenho técnico.
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
		queue_redraw()
		return

	if is_dash_active:
		_update_active_dash(_delta, move_direction, aim_direction)
		_update_visual_state()
		queue_redraw()
		return

	if _should_start_dash():
		_start_dash(move_direction, aim_direction)
		_update_visual_state()
		queue_redraw()
		return

	runtime_state.apply_input(move_direction, aim_direction)

	velocity = runtime_state.move_direction * runtime_state.move_speed
	move_and_slide()

	_update_visual_state()
	queue_redraw()

## Desenha a direção de mira quando o modo técnico correspondente está ativo.
##
## Este desenho é apenas diagnóstico e não interfere na direção real da arma.
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

## Recebe um ataque e retorna o dano final efetivamente aplicado.
##
## Fluxo:
## - valida payload e estado atual do gameplay;
## - ignora impacto durante invencibilidade;
## - calcula dano após defesa;
## - atualiza o estado runtime;
## - inicia invencibilidade e flash visual;
## - publica eventos de dano e morte;
## - atualiza animação da Queen.
func receive_damage(payload: DamagePayload) -> int:
	if runtime_state == null:
		return 0

	if payload == null:
		return 0

	if not payload.is_valid_payload():
		return 0

	if RunQuery.is_gameplay_blocked(get_tree()):
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
	queue_redraw()

	return final_damage

## Copia a configuração de dash da Queen atual.
func _apply_dash_definition() -> void:
	dash_definition = null

	if queen_definition == null:
		return

	if queen_definition.dash_definition == null:
		return

	if not queen_definition.dash_definition.is_valid_definition():
		push_warning("[PlayerController] DashDefinition inválida para Queen: %s" % queen_definition.id)
		return

	dash_definition = queen_definition.dash_definition

## Configura a área de impacto do dash com base na definição da Queen.
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
		dash_definition.impact_source_id
	)

## Atualiza cooldown do dash.
func _update_dash_cooldown(delta: float) -> void:
	if dash_cooldown_timer <= 0.0:
		dash_cooldown_timer = 0.0
		return

	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)

## Verifica se o dash deve iniciar neste frame.
func _should_start_dash() -> bool:
	if dash_definition == null:
		return false

	if not dash_definition.dash_enabled:
		return false

	if dash_cooldown_timer > 0.0:
		return false

	if is_dash_active:
		return false

	if RunQuery.is_gameplay_blocked(get_tree()):
		return false

	return InputManager.was_dash_just_pressed()

## Inicia o dash da Queen.
func _start_dash(move_direction: Vector2, aim_direction: Vector2) -> void:
	if dash_definition == null:
		return

	var dash_direction: Vector2 = _resolve_dash_direction(
		move_direction,
		aim_direction
	)

	if dash_direction.length() <= 0.001:
		return

	is_dash_active = true
	_apply_dash_collision_mode(true)
	active_dash_direction = dash_direction.normalized()
	dash_timer = max(0.01, dash_definition.dash_duration_seconds)
	dash_cooldown_timer = max(0.0, dash_definition.dash_cooldown_seconds)
	active_dash_speed = (
		max(0.0, dash_definition.dash_distance_pixels)
		/ dash_timer
	)

	runtime_state.start_dash(active_dash_direction, aim_direction)

	if dash_impact_area != null:
		dash_impact_area.activate_for_dash(active_dash_direction)
	
	_update_visual_state()

## Atualiza movimento enquanto o dash está ativo.
func _update_active_dash(
	delta: float,
	move_direction: Vector2,
	aim_direction: Vector2
) -> void:
	if dash_definition == null:
		_finish_dash(move_direction, aim_direction)
		return

	dash_timer -= delta

	runtime_state.update_dash(active_dash_direction, aim_direction)

	velocity = active_dash_direction * active_dash_speed
	move_and_slide()

	if dash_timer <= 0.0:
		_finish_dash(move_direction, aim_direction)

## Finaliza o dash e devolve controle ao movimento normal.
func _finish_dash(move_direction: Vector2, aim_direction: Vector2) -> void:
	is_dash_active = false
	dash_timer = 0.0
	active_dash_direction = Vector2.ZERO
	active_dash_speed = 0.0

	if dash_impact_area != null:
		dash_impact_area.deactivate()

	_apply_dash_collision_mode(false)
	
	runtime_state.finish_dash(move_direction, aim_direction)

## Cancela dash ativo sem tentar continuar movimento.
func _cancel_active_dash() -> void:
	is_dash_active = false
	dash_timer = 0.0
	active_dash_direction = Vector2.ZERO
	active_dash_speed = 0.0

	if dash_impact_area != null:
		dash_impact_area.deactivate()

	if runtime_state != null:
		runtime_state.is_dashing = false
		runtime_state.dash_direction = Vector2.ZERO
		
	_apply_dash_collision_mode(false)

## Resolve a direção do dash.
##
## Prioridade:
## 1. movimento atual;
## 2. última direção de movimento registrada;
## 3. mira atual;
## 4. última mira válida;
## 5. direita.
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

## Alterna a colisão corporal da Gaia durante o dash.
##
## Durante o dash, a Gaia deixa de colidir com EnemyBody para conseguir
## atravessar grupos. Ela continua usando PlayerHurtbox e ainda pode
## receber dano por EnemyAttackHitbox.
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

## Configura a área vulnerável da Queen com base em sua definition.
##
## Mantém a BodyCollision responsável por movimento separada da região
## utilizada para receber ataques inimigos.
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

## Encaminha o estado runtime atual para o controller visual da Queen.
##
## O visual decide qual animação executar com base no estado recebido.
func _update_visual_state() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	if visual_controller.has_method("apply_runtime_state"):
		visual_controller.call("apply_runtime_state", runtime_state)

## Resolve o controller visual da Queen.
##
## Prioridade:
## 1. caminho informado no Inspector;
## 2. node conhecido `VisualRoot/GaiaVisual`;
## 3. busca recursiva por método `apply_runtime_state`.
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

## Resolve a área de impacto do dash.
##
## Prioridade:
## 1. caminho configurado no Inspector;
## 2. node direto `DashImpactArea`;
## 3. busca recursiva por PlayerDashImpactArea.
func _resolve_dash_impact_area() -> PlayerDashImpactArea:
	if dash_impact_area_path != NodePath():
		var configured_area: Node = get_node_or_null(dash_impact_area_path)

		if configured_area is PlayerDashImpactArea:
			return configured_area as PlayerDashImpactArea

	var direct_area: Node = get_node_or_null("DashImpactArea")

	if direct_area is PlayerDashImpactArea:
		return direct_area as PlayerDashImpactArea

	return _find_first_dash_impact_area(self)

## Busca recursivamente a primeira PlayerDashImpactArea.
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

## Procura recursivamente um node que implemente determinado método.
##
## Utilizado como fallback desacoplado para controllers visuais.
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

## Aplica um upgrade selecionado durante a run.
##
## Upgrades próprios do player são tratados diretamente neste controller.
## Upgrades pertencentes a armas são encaminhados para nodes do grupo
## `player_weapon`.
##
## Retorna `true` somente quando o upgrade foi efetivamente aplicado,
## permitindo ao `RunController` consumir a escolha de forma segura.
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

		_:
			if not UpgradeTypes.is_weapon_upgrade(upgrade.upgrade_type):
				push_warning("[PlayerController] Tipo de upgrade não suportado: %s" % upgrade.upgrade_type)
				return false

			if not _forward_upgrade_to_weapons(upgrade):
				return false

	_update_visual_state()
	queue_redraw()

	return true

## Encaminha um upgrade de arma para todos os controllers de arma ativos.
##
## Retorna sucesso quando ao menos uma arma aceitou e aplicou a melhoria.
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

## Retorna o estado runtime atual da Queen.
##
## Utilizado por arma, inimigos, moedas e sistemas de diagnóstico.
func get_runtime_state() -> PlayerRuntimeState:
	return runtime_state

## Retorna informações técnicas do player para overlay e auditoria.
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

## Retorna modificadores utilizados pelos drops físicos de moeda.
##
## O `CoinDrop` consulta esta estrutura para calcular seus raios
## efetivos de magnetismo e coleta.
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

## Atualiza o tempo restante da invencibilidade temporária após dano.
func _update_invincibility(delta: float) -> void:
	if runtime_state == null:
		return

	if not runtime_state.is_invincible:
		return

	runtime_state.invincibility_timer -= delta

	if runtime_state.invincibility_timer <= 0.0:
		runtime_state.invincibility_timer = 0.0
		runtime_state.is_invincible = false

## Inicia uma nova janela de invencibilidade após dano válido.
##
## Quando a duração configurada for inválida, garante que a Queen
## permaneça imediatamente vulnerável.
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

## Solicita ao controller visual o feedback de impacto recebido.
##
## Atualmente dispara o flash vermelho temporário da Gaia.
func _play_damage_feedback() -> void:
	if not play_visual_damage_flash:
		return

	if visual_controller == null:
		return

	if visual_controller.has_method("play_damage_flash"):
		visual_controller.call("play_damage_flash")
