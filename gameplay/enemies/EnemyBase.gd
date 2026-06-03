## Controller base do inimigo perseguidor utilizado no Módulo 1.
##
## Responsabilidades:
## - aplicar atributos a partir de `EnemyDefinition`;
## - localizar e perseguir a Queen;
## - configurar hitbox ofensiva e hurtbox independentes;
## - receber dano composto da arma;
## - receber knockback configurável de armas/dash/impactos;
## - acionar feedback visual de dano recebido;
## - emitir XP e chance de moeda ao morrer;
## - coordenar animação e remoção visual após a morte.
##
## O inimigo atual é simples e persegue diretamente o player.
## O movimento orgânico atual é baseado em:
## - perseguição direta;
## - esbarrão físico leve entre inimigos;
## - knockback externo temporário quando atingido.
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

## Define se esta instância responde a esbarrões corporais com outros inimigos.
var body_bump_enabled: bool = true

## Nível de força/massa utilizado para comparar esbarrões entre inimigos.
var body_bump_power: float = 2.0

## Multiplicador que converte o nível de esbarrão em velocidade externa.
var body_bump_velocity_per_power: float = 24.0

## Velocidade máxima permitida para o impulso externo de esbarrão.
var body_bump_max_velocity: float = 140.0

## Velocidade de dissipação do impulso externo.
var body_bump_decay_per_second: float = 280.0

## Quanto do esbarrão será convertido em movimento lateral.
var body_bump_lateral_influence: float = 0.35

## Velocidade externa temporária causada por esbarrões.
##
## Essa velocidade é somada à perseguição normal da Gaia e desaparece
## gradualmente. Ela não causa dano e não interfere em Hitbox/Hurtbox.
var body_bump_velocity: Vector2 = Vector2.ZERO

## Multiplicador aplicado ao knockback recebido por armas e impactos.
var received_knockback_multiplier: float = 1.0

## Limite máximo da velocidade temporária gerada por knockback.
var received_knockback_max_velocity: float = 520.0

## Velocidade com que o knockback desaparece.
var received_knockback_decay_per_second: float = 1800.0

## Peso da perseguição normal enquanto o inimigo está sendo empurrado.
var received_knockback_chase_weight: float = 0.15

## Velocidade temporária gerada por knockback recebido.
##
## O knockback agora usa o mesmo princípio do body bump: velocidade externa
## temporária que é somada ao movimento e dissipada gradualmente.
var received_knockback_velocity: Vector2 = Vector2.ZERO

## XP concedida ao morrer.
var xp_reward: int = 1

## Chance de gerar moeda física ao morrer.
var coin_drop_chance: float = 0.25

## Valor da moeda gerada, quando houver drop.
var coin_drop_value: int = 1

## Referência da Queen perseguida.
var target_node: Node2D = null

## Direção visual principal usada pelo Goblin para orientar animação/facing.
##
## Diferente de `velocity`, esta direção representa a intenção de perseguição
## em direção à Gaia. Ela ignora impulsos temporários para que o inimigo
## possa deslizar fisicamente sem parecer correr para o lado oposto.
var visual_chase_direction: Vector2 = Vector2.RIGHT

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
		body_bump_velocity = Vector2.ZERO
		_clear_received_knockback()
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	if not is_alive:
		velocity = Vector2.ZERO
		body_bump_velocity = Vector2.ZERO
		_clear_received_knockback()
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	if target_node == null:
		target_node = _resolve_target()

	if target_node == null:
		velocity = Vector2.ZERO
		body_bump_velocity = Vector2.ZERO
		_clear_received_knockback()
		move_and_slide()
		_update_visual_state()
		queue_redraw()
		return

	_update_body_bump_velocity(_delta)
	_update_received_knockback_velocity(_delta)

	_follow_target()

	# Durante knockback, a perseguição continua existindo, mas perde força.
	# Isso permite que a Gaia abra espaço sem desligar a IA simples do Goblin.
	if _is_received_knockback_active():
		velocity *= received_knockback_chase_weight

	velocity += body_bump_velocity
	velocity += received_knockback_velocity

	move_and_slide()
	_process_body_bump_collisions()

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

	var forward_direction: Vector2 = visual_chase_direction

	if forward_direction.length() <= 0.001:
		forward_direction = Vector2.RIGHT

	var nose_position: Vector2 = forward_direction.normalized() * (debug_radius + 8.0)
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
	body_bump_velocity = Vector2.ZERO
	_clear_received_knockback()

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
## - a ContactAttackHitbox que causa dano à PlayerHurtbox;
## - o esbarrão corporal;
## - o knockback recebido.
func _apply_definition() -> void:
	if enemy_definition == null:
		enemy_id = "enemy_undefined"
		max_hp = 10
		current_hp = max_hp
		move_speed = 90.0

		body_bump_enabled = true
		body_bump_power = 2.0
		body_bump_velocity_per_power = 24.0
		body_bump_max_velocity = 140.0
		body_bump_decay_per_second = 280.0
		body_bump_lateral_influence = 0.35
		body_bump_velocity = Vector2.ZERO

		received_knockback_multiplier = 1.0
		received_knockback_max_velocity = 520.0
		received_knockback_decay_per_second = 1800.0
		received_knockback_chase_weight = 0.15
		_clear_received_knockback()

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

	body_bump_enabled = enemy_definition.body_bump_enabled
	body_bump_power = max(0.0, enemy_definition.body_bump_power)
	body_bump_velocity_per_power = max(0.0, enemy_definition.body_bump_velocity_per_power)
	body_bump_max_velocity = max(0.0, enemy_definition.body_bump_max_velocity)
	body_bump_decay_per_second = max(0.0, enemy_definition.body_bump_decay_per_second)
	body_bump_lateral_influence = clamp(enemy_definition.body_bump_lateral_influence, 0.0, 1.0)
	body_bump_velocity = Vector2.ZERO

	received_knockback_multiplier = max(0.0, enemy_definition.received_knockback_multiplier)
	received_knockback_max_velocity = max(0.0, enemy_definition.received_knockback_max_velocity)
	received_knockback_decay_per_second = max(0.0, enemy_definition.received_knockback_decay_per_second)
	received_knockback_chase_weight = clamp(
		enemy_definition.received_knockback_chase_weight,
		0.0,
		1.0
	)
	_clear_received_knockback()

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
## A lógica de movimento continua buscando o centro da Queen.
## A direção visual de perseguição é armazenada separadamente para que
## impulsos externos não façam a animação virar para o lado errado.
func _follow_target() -> void:
	var to_target: Vector2 = target_node.global_position - global_position
	var distance_to_target: float = to_target.length()

	if distance_to_target > 0.001:
		visual_chase_direction = to_target.normalized()

	if distance_to_target <= stopping_distance:
		velocity = Vector2.ZERO
		return

	velocity = visual_chase_direction * move_speed

## Dissipa gradualmente a velocidade externa gerada por esbarrões.
##
## A perseguição principal continua sendo recalculada todo frame em
## `_follow_target()`. Este vetor apenas adiciona um pequeno deslocamento
## temporário para reduzir empilhamento entre inimigos.
func _update_body_bump_velocity(delta: float) -> void:
	if body_bump_velocity.length() <= 0.001:
		body_bump_velocity = Vector2.ZERO
		return

	var decay_amount: float = body_bump_decay_per_second * delta
	body_bump_velocity = body_bump_velocity.move_toward(Vector2.ZERO, decay_amount)

## Analisa colisões corporais geradas por `move_and_slide()` e aplica
## uma resposta leve quando o collider também é um inimigo vivo.
##
## Importante:
## - isso não causa dano;
## - isso não consulta Hurtbox;
## - isso não consulta Hitbox;
## - isso existe apenas para movimento corporal orgânico.
func _process_body_bump_collisions() -> void:
	if not body_bump_enabled:
		return

	if body_bump_power <= 0.0:
		return

	var processed_colliders: Dictionary = {}

	for collision_index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(collision_index)

		if collision == null:
			continue

		var collider_object: Object = collision.get_collider()

		if not collider_object is Node2D:
			continue

		var other_enemy: Node2D = collider_object as Node2D

		if other_enemy == self:
			continue

		if not other_enemy.is_in_group("enemy"):
			continue

		var other_instance_id: int = int(other_enemy.get_instance_id())

		if processed_colliders.has(other_instance_id):
			continue

		processed_colliders[other_instance_id] = true

		if other_enemy.has_method("is_enemy_alive"):
			var other_alive_variant: Variant = other_enemy.call("is_enemy_alive")

			if other_alive_variant is bool and not bool(other_alive_variant):
				continue

		var other_body_bump_power: float = body_bump_power

		if other_enemy.has_method("get_body_bump_power"):
			var other_power_variant: Variant = other_enemy.call("get_body_bump_power")

			if other_power_variant is float or other_power_variant is int:
				other_body_bump_power = float(other_power_variant)

		var received_bump_power: float = _calculate_received_body_bump_power(
			other_body_bump_power
		)

		if received_bump_power <= 0.0:
			continue

		var bump_direction: Vector2 = _get_body_bump_direction_from(other_enemy)

		if bump_direction.length() <= 0.001:
			continue

		_add_body_bump_velocity(bump_direction, received_bump_power)

## Calcula quanto este inimigo deve ser empurrado ao colidir com outro.
##
## Regra:
## - forças iguais: ambos recebem seu próprio valor;
## - força menor contra maior: menor recebe a diferença;
## - força maior contra menor: maior não é empurrado.
func _calculate_received_body_bump_power(other_body_bump_power: float) -> float:
	var own_power: float = max(0.0, body_bump_power)
	var other_power: float = max(0.0, other_body_bump_power)

	if own_power <= 0.0 and other_power <= 0.0:
		return 0.0

	if is_equal_approx(own_power, other_power):
		return own_power

	if own_power < other_power:
		return other_power - own_power

	return 0.0

## Resolve a direção do esbarrão a partir da posição do outro inimigo.
##
## Além do afastamento direto, adiciona uma pequena influência lateral
## configurável para gerar deslizamento mais orgânico ao redor da Gaia.
func _get_body_bump_direction_from(other_enemy: Node2D) -> Vector2:
	if other_enemy == null:
		return Vector2.ZERO

	var away_direction: Vector2 = global_position - other_enemy.global_position

	if away_direction.length() <= 0.001:
		if velocity.length() > 0.001:
			away_direction = -velocity.normalized()
		else:
			away_direction = Vector2.RIGHT

	away_direction = away_direction.normalized()

	if body_bump_lateral_influence <= 0.0:
		return away_direction

	var lateral_direction: Vector2 = Vector2(
		-away_direction.y,
		away_direction.x
	)

	var lateral_sign: float = 1.0

	if int(get_instance_id()) % 2 == 0:
		lateral_sign = -1.0

	var mixed_direction: Vector2 = (
		away_direction
		+ lateral_direction * lateral_sign * body_bump_lateral_influence
	)

	if mixed_direction.length() <= 0.001:
		return away_direction

	return mixed_direction.normalized()

## Adiciona velocidade externa temporária causada por esbarrão.
##
## O limite máximo impede que múltiplas colisões no mesmo frame arremessem
## o inimigo para longe de forma incoerente.
func _add_body_bump_velocity(
	bump_direction: Vector2,
	received_bump_power: float
) -> void:
	if bump_direction.length() <= 0.001:
		return

	if received_bump_power <= 0.0:
		return

	var impulse_velocity: Vector2 = (
		bump_direction.normalized()
		* received_bump_power
		* body_bump_velocity_per_power
	)

	body_bump_velocity += impulse_velocity

	if body_bump_max_velocity > 0.0 and body_bump_velocity.length() > body_bump_max_velocity:
		body_bump_velocity = body_bump_velocity.normalized() * body_bump_max_velocity

## Exposto para outros inimigos compararem força/massa de esbarrão.
func get_body_bump_power() -> float:
	return body_bump_power

## Recebe uma solicitação de knockback causada por arma, dash ou impacto.
##
## A arma informa uma distância em pixels e uma duração. O inimigo converte
## isso em velocidade externa temporária. Essa abordagem segue o mesmo
## padrão simples do body bump, já aprovado na etapa.
func apply_hit_knockback(
	knockback_pixels: float,
	duration_seconds: float,
	source_node: Node = null,
	fallback_direction: Vector2 = Vector2.ZERO
) -> bool:
	if not is_alive:
		return false

	if RunQuery.is_gameplay_blocked(get_tree()):
		return false

	if knockback_pixels <= 0.0:
		return false

	if duration_seconds <= 0.0:
		return false

	if received_knockback_multiplier <= 0.0:
		return false

	var knockback_direction: Vector2 = _resolve_received_knockback_direction(
		source_node,
		fallback_direction
	)

	if knockback_direction.length() <= 0.001:
		return false

	var effective_pixels: float = knockback_pixels * received_knockback_multiplier
	var impulse_speed: float = effective_pixels / max(0.01, duration_seconds)
	var impulse_velocity: Vector2 = knockback_direction.normalized() * impulse_speed

	received_knockback_velocity += impulse_velocity

	if (
		received_knockback_max_velocity > 0.0
		and received_knockback_velocity.length() > received_knockback_max_velocity
	):
		received_knockback_velocity = (
			received_knockback_velocity.normalized()
			* received_knockback_max_velocity
		)
		
	return true

## Dissipa gradualmente a velocidade externa gerada por knockback recebido.
func _update_received_knockback_velocity(delta: float) -> void:
	if received_knockback_velocity.length() <= 0.001:
		received_knockback_velocity = Vector2.ZERO
		return

	var decay_amount: float = received_knockback_decay_per_second * delta
	received_knockback_velocity = received_knockback_velocity.move_toward(
		Vector2.ZERO,
		decay_amount
	)

## Retorna se existe knockback ativo nesta instância.
func _is_received_knockback_active() -> bool:
	return received_knockback_velocity.length() > 0.001

## Limpa qualquer knockback recebido em andamento.
func _clear_received_knockback() -> void:
	received_knockback_velocity = Vector2.ZERO

## Resolve a direção final do knockback recebido.
##
## Prioridade:
## 1. se não houver source e houver fallback, usa o fallback diretamente;
## 2. para longe da fonte do ataque;
## 3. oposto da direção de perseguição visual;
## 4. oposto da velocidade física atual;
## 5. direção do ataque como fallback.
##
## O caso 1 existe para dash: a DashImpactArea pode pedir knockback
## diretamente na direção do dash, abrindo caminho para a Queen.
func _resolve_received_knockback_direction(
	source_node: Node = null,
	fallback_direction: Vector2 = Vector2.ZERO
) -> Vector2:
	if source_node == null and fallback_direction.length() > 0.001:
		return fallback_direction.normalized()

	if source_node is Node2D:
		var source_node_2d: Node2D = source_node as Node2D
		var away_from_source: Vector2 = global_position - source_node_2d.global_position

		if away_from_source.length() > 0.001:
			return away_from_source.normalized()

	if visual_chase_direction.length() > 0.001:
		return -visual_chase_direction.normalized()

	if velocity.length() > 0.001:
		return -velocity.normalized()

	if fallback_direction.length() > 0.001:
		return fallback_direction.normalized()

	return Vector2.ZERO

## Exposto para colisões consultarem se esta instância ainda participa
## do gameplay ativo.
func is_enemy_alive() -> bool:
	return is_alive

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
##
## O visual usa a intenção de perseguição para orientar o corpo.
## A velocidade física final pode conter esbarrão lateral ou recuo leve,
## mas isso não deve inverter a animação do Goblin.
func _update_visual_state() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	var is_moving: bool = (
		is_alive
		and (
			velocity.length() > 0.001
			or body_bump_velocity.length() > 0.001
			or received_knockback_velocity.length() > 0.001
		)
	)

	var movement_direction: Vector2 = Vector2.ZERO

	if is_moving:
		movement_direction = _get_visual_movement_direction()

	if visual_controller.has_method("apply_enemy_runtime_state"):
		visual_controller.call(
			"apply_enemy_runtime_state",
			is_moving,
			movement_direction,
			is_alive
		)

## Retorna a direção usada exclusivamente para animação/facing.
##
## Sempre que possível, aponta para a Gaia. Caso o alvo esteja ausente
## momentaneamente, mantém a última direção válida para evitar flips falsos.
func _get_visual_movement_direction() -> Vector2:
	if target_node != null and is_instance_valid(target_node):
		var to_target: Vector2 = target_node.global_position - global_position

		if to_target.length() > 0.001:
			visual_chase_direction = to_target.normalized()

	return visual_chase_direction

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
		"xp_reward": xp_reward,
		"body_bump_velocity": body_bump_velocity,
		"received_knockback_velocity": received_knockback_velocity,
		"received_knockback_multiplier": received_knockback_multiplier,
		"received_knockback_chase_weight": received_knockback_chase_weight
	}
