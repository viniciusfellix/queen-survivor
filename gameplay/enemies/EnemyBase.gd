## Controller base do inimigo perseguidor utilizado no Módulo 1.
##
## Responsabilidades:
## - aplicar atributos a partir de `EnemyDefinition`;
## - localizar e perseguir a Queen;
## - configurar hitbox ofensiva e hurtbox independentes;
## - receber dano composto da arma;
## - acionar feedback visual de dano recebido;
## - emitir XP e chance de moeda ao morrer;
## - coordenar animação e remoção visual após a morte.
##
## O inimigo atual é simples e persegue diretamente o player.
## Melhorias futuras, como distribuição orgânica ao redor da Queen,
## poderão substituir especificamente a lógica de perseguição.
extends CharacterBody2D

## Dados de balanceamento utilizados por esta instância.
@export var enemy_definition: EnemyDefinition

## Caminho opcional para um alvo específico.
@export var target_path: NodePath

## Grupo utilizado para localizar automaticamente a Queen.
@export var target_group_name: String = "player"

## Caminho opcional para o controller visual do inimigo.
@export var visual_controller_path: NodePath

## Distância mínima na qual o inimigo interrompe o deslocamento.
@export var stopping_distance: float = 8.0

## Exibe o placeholder técnico do corpo do inimigo.
@export var draw_debug_visual: bool = false

## Exibe linha técnica conectando inimigo ao alvo atual.
@export var draw_debug_target_line: bool = false

@onready var hurtbox_component: HurtboxComponent = get_node_or_null("Hurtbox") as HurtboxComponent

## Hitbox ofensiva responsável pelo ataque corporal contra a Queen.
@onready var contact_attack_hitbox: EnemyAttackHitbox = (
	get_node_or_null("ContactAttackHitbox") as EnemyAttackHitbox
)

## Tempo em que o corpo morto permanece visível antes de ser removido.
@export var remove_after_death_seconds: float = 0.45

## Vida máxima atual desta instância.
var max_hp: int = 10

## Vida restante desta instância.
var current_hp: int = 10

## Velocidade atual de perseguição.
var move_speed: float = 90.0

## XP concedida ao morrer.
var xp_reward: int = 1

## Chance de gerar moeda física ao morrer.
var coin_drop_chance: float = 0.25

## Valor da moeda gerada, quando houver drop.
var coin_drop_value: int = 1

## Referência da Queen perseguida.
var target_node: Node2D = null

## Referência do controller visual desta instância.
var visual_controller: Node = null

## ID técnico do inimigo configurado.
var enemy_id: String = ""

## Cor utilizada pelo placeholder técnico.
var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)

## Raio utilizado pelo placeholder técnico.
var debug_radius: float = 18.0

## Informa se o inimigo ainda está ativo em gameplay.
var is_alive: bool = true

## Soma do dano efetivamente recebido por esta instância.
var total_damage_taken: int = 0

## Último valor de dano efetivamente recebido.
var last_damage_taken: int = 0

## Fonte responsável pelo último dano recebido.
var last_damage_source_id: String = ""

## Inicializa o inimigo, aplica sua definition e tenta resolver alvo e visual.
func _ready() -> void:
	add_to_group("enemy")

	visual_controller = _resolve_visual_controller()

	_apply_definition()
	target_node = _resolve_target()

	if visual_controller == null:
		push_warning("[EnemyBase] Visual controller não encontrado.")

	_update_visual_state()
	queue_redraw()

## Executa perseguição enquanto o gameplay estiver ativo.
##
## O dano não é mais calculado por distância neste controller.
## O contato ofensivo é detectado fisicamente por `ContactAttackHitbox`.
func _physics_process(_delta: float) -> void:
	if RunQuery.is_gameplay_blocked(get_tree()):
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	if not is_alive:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

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

	_update_visual_state()
	queue_redraw()

## Desenha representação técnica do inimigo quando habilitada.
func _draw() -> void:
	if not draw_debug_visual:
		return

	var body_color: Color = debug_color

	if not is_alive:
		body_color = Color(0.25, 0.25, 0.25, 0.7)

	draw_circle(Vector2.ZERO, debug_radius, body_color)
	draw_arc(Vector2.ZERO, debug_radius + 2.0, 0.0, TAU, 24, Color.WHITE, 2.0)

	var forward_direction: Vector2 = Vector2.RIGHT

	if velocity.length() > 0.001:
		forward_direction = velocity.normalized()

	var nose_position: Vector2 = forward_direction * (debug_radius + 8.0)
	draw_circle(nose_position, 4.0, Color.WHITE)

	if draw_debug_target_line and target_node != null:
		var local_target_position: Vector2 = to_local(target_node.global_position)
		draw_line(Vector2.ZERO, local_target_position, Color.YELLOW, 1.0)

## Configura uma instância criada pelo `EnemySpawner`.
##
## Recebe a definition correspondente à wave ativa e, quando disponível,
## recebe diretamente o player como alvo para evitar buscas adicionais.
func setup(definition: EnemyDefinition, target: Node2D = null) -> void:
	enemy_definition = definition

	if target != null:
		target_node = target

	_apply_definition()

	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	_update_visual_state()
	queue_redraw()

## Recebe um payload de ataque da Queen e retorna o dano final aplicado.
##
## O `DamageResolver` calcula individualmente cada componente do ataque
## considerando fraquezas e resistências cadastradas na definition.
func receive_damage(payload: DamagePayload) -> int:
	if payload == null:
		return 0

	if not payload.is_valid_payload():
		return 0

	if RunQuery.is_gameplay_blocked(get_tree()):
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

	DeveloperAuditLogger.log_combat(
		"Dano recebido: enemy=%s raw_total=%s final=%s HP=%s/%s fonte=%s breakdown=%s" % [
			enemy_id,
			str(raw_total),
			str(final_damage),
			str(current_hp),
			str(max_hp),
			payload.source_id,
			_format_damage_breakdown(damage_result)
		],
		"EnemyBase",
		{
			"enemy_id": enemy_id,
			"raw_total": raw_total,
			"final_damage": final_damage,
			"current_hp": current_hp,
			"max_hp": max_hp,
			"source_id": payload.source_id,
			"damage_breakdown": damage_result.get("breakdown", [])
		}
	)
	
	_play_damage_feedback()

	if current_hp <= 0:
		die(payload.source_id)

	_update_visual_state()
	queue_redraw()

	return final_damage

## Consolida a morte desta instância.
##
## Fluxo:
## - bloqueia novas ações;
## - desativa hitbox ofensiva e hurtbox;
## - emite recompensa de XP e dados de moeda;
## - atualiza animação de morte;
## - remove o inimigo do grupo ativo;
## - agenda sua remoção visual após breve delay.
func die(source_id: String = "") -> void:
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO

	if hurtbox_component != null:
		hurtbox_component.set_hurtbox_active(false)

	if contact_attack_hitbox != null:
		contact_attack_hitbox.set_attack_active(false)

	GameEvents.enemy_died.emit(
		enemy_id,
		source_id,
		xp_reward,
		global_position,
		coin_drop_chance,
		coin_drop_value
	)

	DeveloperAuditLogger.log_combat(
		"Inimigo morreu: enemy=%s fonte=%s xp=%s coin_chance=%s coin_value=%s" % [
			enemy_id,
			source_id,
			str(xp_reward),
			str(coin_drop_chance),
			str(coin_drop_value)
		],
		"EnemyBase",
		{
			"enemy_id": enemy_id,
			"source_id": source_id,
			"xp_reward": xp_reward,
			"coin_drop_chance": coin_drop_chance,
			"coin_drop_value": coin_drop_value
		}
	)

	_update_visual_state()

	remove_from_group("enemy")

	var death_timer: SceneTreeTimer = get_tree().create_timer(remove_after_death_seconds)
	death_timer.timeout.connect(_on_death_timer_timeout)

## Remove definitivamente o inimigo após concluir seu tempo visual de morte.
func _on_death_timer_timeout() -> void:
	queue_free()

## Aplica ao runtime os valores presentes na EnemyDefinition ativa.
##
## Além dos atributos e recompensas, esta função configura:
## - a Hurtbox que recebe dano da Gaia;
## - a ContactAttackHitbox que causa dano à PlayerHurtbox.
func _apply_definition() -> void:
	if enemy_definition == null:
		enemy_id = "enemy_undefined"
		max_hp = 10
		current_hp = max_hp
		move_speed = 90.0

		xp_reward = 1
		coin_drop_chance = 0.25
		coin_drop_value = 1

		debug_color = Color(0.9, 0.15, 0.15, 1.0)
		debug_radius = 18.0

		_disable_combat_areas()
		return

	enemy_id = enemy_definition.id
	max_hp = enemy_definition.base_max_hp
	current_hp = max_hp
	move_speed = enemy_definition.base_move_speed

	xp_reward = enemy_definition.xp_reward
	coin_drop_chance = enemy_definition.coin_drop_chance
	coin_drop_value = enemy_definition.coin_drop_value

	debug_color = enemy_definition.debug_color
	debug_radius = enemy_definition.debug_radius

	_configure_hurtbox()
	_configure_contact_attack_hitbox()

## Encaminha ao componente de hurtbox as áreas configuradas no resource
## do inimigo, mantendo a BodyCollision separada da região vulnerável.
func _configure_hurtbox() -> void:
	if hurtbox_component == null:
		hurtbox_component = get_node_or_null("Hurtbox") as HurtboxComponent

	if hurtbox_component == null:
		push_warning("[EnemyBase] HurtboxComponent não encontrado para: %s" % enemy_id)
		return

	if enemy_definition == null:
		return

	hurtbox_component.setup(
		enemy_definition.hurtbox_areas,
		self
	)

## Encaminha ao componente ofensivo o ataque de contato cadastrado
## no resource do inimigo.
func _configure_contact_attack_hitbox() -> void:
	if contact_attack_hitbox == null:
		contact_attack_hitbox = (
			get_node_or_null("ContactAttackHitbox") as EnemyAttackHitbox
		)

	if contact_attack_hitbox == null:
		push_warning("[EnemyBase] ContactAttackHitbox não encontrada para: %s" % enemy_id)
		return

	if enemy_definition == null or not enemy_definition.has_valid_contact_attack():
		contact_attack_hitbox.set_attack_active(false)
		push_warning("[EnemyBase] Ataque de contato inválido para: %s" % enemy_id)
		return

	contact_attack_hitbox.setup(
		enemy_definition.contact_attack,
		self,
		enemy_id
	)

## Desativa hitbox e hurtbox quando não há definition válida.
func _disable_combat_areas() -> void:
	if hurtbox_component != null:
		hurtbox_component.set_hurtbox_active(false)

	if contact_attack_hitbox != null:
		contact_attack_hitbox.set_attack_active(false)

## Atualiza a velocidade de perseguição direta em direção ao player.
##
## A lógica atual desloca cada inimigo diretamente ao centro da Queen.
## O refinamento futuro de ocupação ao redor do player deverá evoluir
## este ponto sem alterar o contrato externo do inimigo.
func _follow_target() -> void:
	var to_target: Vector2 = target_node.global_position - global_position
	var distance_to_target: float = to_target.length()

	if distance_to_target <= stopping_distance:
		velocity = Vector2.ZERO
		return

	var direction: Vector2 = to_target.normalized()
	velocity = direction * move_speed

## Solicita ao controller visual o flash de impacto recebido.
##
## Atualmente executa um breve flash branco no Goblin.
func _play_damage_feedback() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	if visual_controller.has_method("play_damage_flash"):
		visual_controller.call("play_damage_flash")

## Encaminha estado de movimento e vida ao controller visual do inimigo.
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

## Resolve o controller visual associado ao inimigo.
##
## Prioridade:
## 1. caminho configurado;
## 2. node padrão do Goblin;
## 3. busca por método compatível dentro de `VisualRoot`.
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

## Busca recursivamente um node que implemente determinado método.
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

## Resolve o alvo atual do inimigo.
##
## Prioridade:
## 1. caminho explícito;
## 2. primeiro Node2D encontrado no grupo configurado.
func _resolve_target() -> Node2D:
	if target_path != NodePath():
		var configured_target: Node = get_node_or_null(target_path)

		if configured_target is Node2D:
			return configured_target as Node2D

	var group_target: Node2D = _find_first_node2d_in_group(target_group_name)

	if group_target != null:
		return group_target

	return null

## Retorna o primeiro `Node2D` registrado em determinado grupo.
func _find_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null

## Converte o breakdown calculado pelo resolver em texto legível para logs.
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

## Retorna informações técnicas da instância para overlay e auditoria.
func get_debug_data() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"move_speed": move_speed,
		"global_position": global_position,
		"has_target": target_node != null,
		"has_visual": visual_controller != null,
		"has_hurtbox": hurtbox_component != null,
		"has_contact_attack_hitbox": contact_attack_hitbox != null,
		"has_valid_contact_attack": (
			enemy_definition != null
			and enemy_definition.has_valid_contact_attack()
		),
		"is_alive": is_alive,
		"total_damage_taken": total_damage_taken,
		"last_damage_taken": last_damage_taken,
		"last_damage_source_id": last_damage_source_id,
		"xp_reward": xp_reward
	}
