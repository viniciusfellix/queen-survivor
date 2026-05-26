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

## Controller visual responsável pelas animações e flash de dano.
@onready var visual_controller: Node = _resolve_visual_controller()

## Hurtbox responsável por receber ataques de inimigos.
@onready var player_hurtbox: HurtboxComponent = (
	get_node_or_null("PlayerHurtbox") as HurtboxComponent
)

@export_group("Damage Feedback")

## Ativa a pequena janela de invencibilidade após receber dano.
@export var enable_hit_invincibility: bool = true

## Duração, em segundos, da invencibilidade após impacto.
@export var invincibility_duration_after_hit: float = 0.5

## Define se o visual da Queen pisca ao receber dano.
@export var play_visual_damage_flash: bool = true

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

	_configure_player_hurtbox()

	if visual_controller == null:
		push_warning("[PlayerController] visual_controller não encontrado. Verifique visual_controller_path.")

	_update_visual_state()
	queue_redraw()

## Executa o ciclo físico da personagem.
##
## Fluxo normal:
## - reduz tempo restante de invencibilidade;
## - obtém movimento e mira atuais;
## - bloqueia movimento quando a Queen morreu;
## - movimenta a personagem enquanto viva;
## - sincroniza animações e desenho técnico.
func _physics_process(_delta: float) -> void:
	_update_invincibility(_delta)

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
