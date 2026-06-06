## Classe base runtime de inimigo.
##
## Responsabilidades:
## - receber EnemyDefinition;
## - configurar HP, recompensas, hurtbox e ataque;
## - perseguir a Gaia;
## - combinar velocidades físicas de perseguição, body bump, slide e knockback;
## - receber dano via Hurtbox/Hitbox;
## - morrer emitindo XP e chance de moeda;
## - atualizar visual Spine sem usar animação como regra de gameplay.
##
## Decisão arquitetural:
## BodyCollision é apenas física/movimento.
## Dano do inimigo é feito por EnemyAttackHitbox contra PlayerHurtbox.
## Dano recebido vem de PlayerAttackHitbox/DirectionalAttackHitbox contra EnemyHurtbox.
extends CharacterBody2D
class_name EnemyBase

@export var enemy_definition: EnemyDefinition
@export var target_path: NodePath
@export var target_group_name: String = "player"
@export var visual_controller_path: NodePath
@export var stopping_distance: float = 8.0
@export var draw_debug_visual: bool = false
@export var draw_debug_target_line: bool = false
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("Hurtbox") as HurtboxComponent
@onready var contact_attack_hitbox: EnemyAttackHitbox = (
	get_node_or_null("ContactAttackHitbox") as EnemyAttackHitbox
)
@export var remove_after_death_seconds: float = 0.45

## Estado runtime básico de vida/movimento copiado do EnemyDefinition.
var max_hp: int = 10
var current_hp: int = 10
var move_speed: float = 90.0
## Parâmetros runtime de esbarrão físico entre inimigos.
var body_bump_enabled: bool = true
var body_bump_power: float = 2.0
var body_bump_velocity_per_power: float = 24.0
var body_bump_max_velocity: float = 140.0
var body_bump_decay_per_second: float = 280.0
var body_bump_lateral_influence: float = 0.35
var body_bump_velocity: Vector2 = Vector2.ZERO
## Parâmetros runtime para escorregar ao redor da BodyCollision da Gaia.
var player_body_slide_enabled: bool = true
var player_body_slide_power: float = 2.0
var player_body_slide_velocity_per_power: float = 36.0
var player_body_slide_max_velocity: float = 160.0
var player_body_slide_away_influence: float = 0.30
## Parâmetros runtime de knockback recebido por arma, dash ou efeitos futuros.
var received_knockback_multiplier: float = 1.0
var received_knockback_max_velocity: float = 520.0
var received_knockback_decay_per_second: float = 1800.0
var received_knockback_chase_weight: float = 0.15
var received_knockback_velocity: Vector2 = Vector2.ZERO
## Recompensas e referências runtime do inimigo.
var xp_reward: int = 1
var coin_drop_chance: float = 0.25
var coin_drop_value: int = 1
## Referências runtime para alvo e visual.
var target_node: Node2D = null
var visual_chase_direction: Vector2 = Vector2.RIGHT
var visual_controller: Node = null
var enemy_id: String = ""
var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)
var debug_radius: float = 18.0
## Estado de vida e telemetria de dano.
var is_alive: bool = true
var total_damage_taken: int = 0
var last_damage_taken: int = 0
var last_damage_source_id: String = ""
var active_knockback_chase_weight: float = -1.0
var player_body_slide_velocity: Vector2 = Vector2.ZERO
var player_body_slide_decay_per_second: float = 360.0

## Inicializa inimigo, aplica definition, resolve alvo/visual e prepara debug.
func _ready() -> void:
	add_to_group("enemy")

	visual_controller = _resolve_visual_controller()

	_apply_definition()
	target_node = _resolve_target()

	if visual_controller == null:
		push_warning("[EnemyBase] Visual controller não encontrado.")

	_update_visual_state()
	_queue_debug_redraw()

## Atualiza movimento, forças físicas, perseguição e visual a cada frame.
func _physics_process(_delta: float) -> void:
	if not is_alive:
		velocity = Vector2.ZERO
		body_bump_velocity = Vector2.ZERO
		player_body_slide_velocity = Vector2.ZERO
		_clear_received_knockback()
		move_and_slide()
		_update_visual_state()
		_queue_debug_redraw()
		return

	if target_node == null:
		target_node = _resolve_target()

	if target_node == null:
		velocity = Vector2.ZERO
		body_bump_velocity = Vector2.ZERO
		player_body_slide_velocity = Vector2.ZERO
		_clear_received_knockback()
		move_and_slide()
		_update_visual_state()
		_queue_debug_redraw()
		return

	_update_body_bump_velocity(_delta)
	_update_player_body_slide_velocity(_delta)
	_update_received_knockback_velocity(_delta)

	_follow_target()

	if _is_received_knockback_active():
		var current_knockback_chase_weight: float = received_knockback_chase_weight

		if active_knockback_chase_weight >= 0.0:
			current_knockback_chase_weight = active_knockback_chase_weight

		current_knockback_chase_weight = clamp(
			current_knockback_chase_weight,
			0.0,
			1.0
		)

		velocity *= current_knockback_chase_weight

	velocity += body_bump_velocity
	velocity += player_body_slide_velocity
	velocity += received_knockback_velocity

	move_and_slide()
	_process_body_bump_collisions()

	_update_visual_state()
	_queue_debug_redraw()

## Reagenda o _draw apenas quando o visual de debug está ligado.
##
# Evita marcar o canvas como "dirty" a cada frame em centenas de inimigos quando
# o debug está desligado (caso comum); sem isso o _draw nem desenha nada.
func _queue_debug_redraw() -> void:
	if draw_debug_visual:
		queue_redraw()

## Desenha placeholder/debug visual do inimigo e linha até o alvo.
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

## Recebe EnemyDefinition e alvo opcional após instância pelo spawner.
func setup(definition: EnemyDefinition, target: Node2D = null) -> void:
	enemy_definition = definition

	if target != null:
		target_node = target

	_apply_definition()

	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	_update_visual_state()
	_queue_debug_redraw()

## Recebe DamagePayload, calcula dano final, atualiza HP e dispara eventos.
func receive_damage(payload: DamagePayload) -> int:
	if payload == null:
		return 0

	if not payload.is_valid_payload():
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
	_queue_debug_redraw()

	return final_damage

## Finaliza inimigo, desativa combate, emite morte e agenda remoção.
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

## Devolve o inimigo ao pool depois do pequeno delay de morte.
##
## Se o inimigo não tiver vindo do pool, o PoolManager faz queue_free() como fallback.
func _on_death_timer_timeout() -> void:
	PoolManager.despawn(self)

## Hook do pool: restaura o inimigo ao estado de "recém-nascido" antes de reusar.
##
## A configuração de HP/áreas é refeita logo depois pelo setup() do spawner;
## aqui garantimos vida, grupo, velocidades e telemetria zerados.
func _on_pool_acquire() -> void:
	is_alive = true

	velocity = Vector2.ZERO
	body_bump_velocity = Vector2.ZERO
	player_body_slide_velocity = Vector2.ZERO
	_clear_received_knockback()

	total_damage_taken = 0
	last_damage_taken = 0
	last_damage_source_id = ""

	# A morte removeu do grupo; reinsere para voltar a contar como inimigo vivo.
	if not is_in_group("enemy"):
		add_to_group("enemy")

	# Reativa as áreas de combate (o setup ajustará o valor final conforme a definition).
	if hurtbox_component != null:
		hurtbox_component.set_hurtbox_active(true)

	if contact_attack_hitbox != null:
		contact_attack_hitbox.set_attack_active(true)

## Copia dados do EnemyDefinition para estado runtime do inimigo.
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

		player_body_slide_enabled = true
		player_body_slide_power = 2.0
		player_body_slide_velocity_per_power = 36.0
		player_body_slide_max_velocity = 160.0
		player_body_slide_away_influence = 0.30
		player_body_slide_velocity = Vector2.ZERO
		player_body_slide_decay_per_second = 360.0

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
	
	player_body_slide_enabled = enemy_definition.player_body_slide_enabled
	player_body_slide_power = max(0.0, enemy_definition.player_body_slide_power)
	player_body_slide_velocity_per_power = max(0.0, enemy_definition.player_body_slide_velocity_per_power)
	player_body_slide_max_velocity = max(0.0, enemy_definition.player_body_slide_max_velocity)
	player_body_slide_away_influence = clamp(
		enemy_definition.player_body_slide_away_influence,
		0.0,
		1.0
	)
	player_body_slide_velocity = Vector2.ZERO
	player_body_slide_decay_per_second = max(
		0.0,
		enemy_definition.player_body_slide_decay_per_second
	)

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

## Configura HurtboxComponent com áreas vulneráveis do EnemyDefinition.
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

## Configura EnemyAttackHitbox com o ataque de contato do EnemyDefinition.
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

## Desativa hurtbox e hitbox quando inimigo não pode mais combater.
func _disable_combat_areas() -> void:
	if hurtbox_component != null:
		hurtbox_component.set_hurtbox_active(false)

	if contact_attack_hitbox != null:
		contact_attack_hitbox.set_attack_active(false)

## Calcula perseguição direta em direção à Gaia.
func _follow_target() -> void:
	var to_target: Vector2 = target_node.global_position - global_position
	var distance_to_target: float = to_target.length()

	if distance_to_target > 0.001:
		visual_chase_direction = to_target.normalized()

	if distance_to_target <= stopping_distance:
		velocity = Vector2.ZERO
		return

	velocity = visual_chase_direction * move_speed

## Aplica decaimento da velocidade de esbarrão entre inimigos.
func _update_body_bump_velocity(delta: float) -> void:
	if body_bump_velocity.length() <= 0.001:
		body_bump_velocity = Vector2.ZERO
		return

	var decay_amount: float = body_bump_decay_per_second * delta
	body_bump_velocity = body_bump_velocity.move_toward(Vector2.ZERO, decay_amount)

## Lê colisões do move_and_slide e gera body bump ou player body slide.
func _process_body_bump_collisions() -> void:
	var processed_colliders: Dictionary = {}

	for collision_index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(collision_index)

		if collision == null:
			continue

		var collider_object: Object = collision.get_collider()

		if not collider_object is Node2D:
			continue

		var collider_node: Node2D = collider_object as Node2D
		var collider_instance_id: int = int(collider_node.get_instance_id())

		if processed_colliders.has(collider_instance_id):
			continue

		processed_colliders[collider_instance_id] = true

		if _is_player_body_collider(collider_node):
			_process_player_body_slide_collision(collider_node)
			continue

		if not body_bump_enabled:
			continue

		if body_bump_power <= 0.0:
			continue

		var other_enemy: Node2D = collider_node

		if other_enemy == self:
			continue

		if not other_enemy.is_in_group("enemy"):
			continue

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

## Calcula quanto bump este inimigo recebe ao colidir com outro.
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

## Calcula direção de afastamento/lateralização ao esbarrar em outro inimigo.
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

## Adiciona impulso de body bump respeitando velocidade máxima.
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

## Identifica se o collider representa o corpo do player/Gaia.
func _is_player_body_collider(collider_node: Node2D) -> bool:
	if collider_node == null:
		return false

	if target_node != null and collider_node == target_node:
		return true

	if target_group_name.strip_edges() != "" and collider_node.is_in_group(target_group_name):
		return true

	if collider_node.is_in_group("player"):
		return true

	return false

## Processa escorregamento ao colidir com a BodyCollision da Gaia.
func _process_player_body_slide_collision(player_body: Node2D) -> void:
	if not player_body_slide_enabled:
		return

	if player_body_slide_power <= 0.0:
		return

	if player_body_slide_velocity_per_power <= 0.0:
		return

	var slide_direction: Vector2 = _get_player_body_slide_direction(player_body)

	if slide_direction.length() <= 0.001:
		return

	_add_player_body_slide_velocity(slide_direction)

## Calcula direção lateral/afastamento para deslizar ao redor da Gaia.
func _get_player_body_slide_direction(player_body: Node2D) -> Vector2:
	if player_body == null:
		return Vector2.ZERO

	var away_direction: Vector2 = global_position - player_body.global_position

	if away_direction.length() <= 0.001:
		if visual_chase_direction.length() > 0.001:
			away_direction = -visual_chase_direction.normalized()
		elif velocity.length() > 0.001:
			away_direction = -velocity.normalized()
		else:
			away_direction = Vector2.RIGHT

	away_direction = away_direction.normalized()

	var lateral_direction: Vector2 = Vector2(
		-away_direction.y,
		away_direction.x
	).normalized()

	var lateral_sign: float = _get_player_body_slide_lateral_sign(lateral_direction)
	var slide_direction: Vector2 = lateral_direction * lateral_sign

	if player_body_slide_away_influence > 0.0:
		slide_direction += away_direction * player_body_slide_away_influence

	if slide_direction.length() <= 0.001:
		return away_direction

	return slide_direction.normalized()

## Decide lado preferencial do slide para reduzir inversões/jitter.
func _get_player_body_slide_lateral_sign(lateral_direction: Vector2) -> float:
	if velocity.length() > 0.001:
		var velocity_side: float = velocity.normalized().dot(lateral_direction)

		if velocity_side < -0.05:
			return -1.0

		if velocity_side > 0.05:
			return 1.0

	if int(get_instance_id()) % 2 == 0:
		return -1.0

	return 1.0

## Aplica impulso de slide do player respeitando velocidade máxima.
func _add_player_body_slide_velocity(slide_direction: Vector2) -> void:
	if slide_direction.length() <= 0.001:
		return

	var impulse_velocity: Vector2 = (
		slide_direction.normalized()
		* player_body_slide_power
		* player_body_slide_velocity_per_power
	)

	player_body_slide_velocity += impulse_velocity

	if (
		player_body_slide_max_velocity > 0.0
		and player_body_slide_velocity.length() > player_body_slide_max_velocity
	):
		player_body_slide_velocity = (
			player_body_slide_velocity.normalized()
			* player_body_slide_max_velocity
		)

## Expõe força de body bump para outros inimigos calcularem colisões.
func get_body_bump_power() -> float:
	return body_bump_power

## Aplica knockback externo vindo de arma, dash ou efeitos futuros.
func apply_hit_knockback(
	knockback_pixels: float,
	duration_seconds: float,
	source_node: Node = null,
	fallback_direction: Vector2 = Vector2.ZERO,
	max_velocity_override: float = 0.0,
	chase_weight_override: float = -1.0
) -> bool:
	if not is_alive:
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
	active_knockback_chase_weight = chase_weight_override

	var max_velocity_to_use: float = received_knockback_max_velocity

	if max_velocity_override > 0.0:
		max_velocity_to_use = max_velocity_override

	if (
		max_velocity_to_use > 0.0
		and received_knockback_velocity.length() > max_velocity_to_use
	):
		received_knockback_velocity = (
			received_knockback_velocity.normalized()
			* max_velocity_to_use
		)

	return true

## Aplica decaimento do knockback recebido.
func _update_received_knockback_velocity(delta: float) -> void:
	if received_knockback_velocity.length() <= 0.001:
		received_knockback_velocity = Vector2.ZERO
		return

	var decay_amount: float = received_knockback_decay_per_second * delta
	received_knockback_velocity = received_knockback_velocity.move_toward(
		Vector2.ZERO,
		decay_amount
	)

## Informa se existe knockback recebido ainda ativo.
func _is_received_knockback_active() -> bool:
	return received_knockback_velocity.length() > 0.001

## Limpa knockback recebido e override de chase weight.
func _clear_received_knockback() -> void:
	received_knockback_velocity = Vector2.ZERO
	active_knockback_chase_weight = -1.0

## Resolve direção do knockback usando fonte, fallback ou movimento atual.
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

## Retorna se o inimigo ainda está vivo.
func is_enemy_alive() -> bool:
	return is_alive

## Solicita flash/feedback visual ao visual controller.
func _play_damage_feedback() -> void:
	if visual_controller == null:
		visual_controller = _resolve_visual_controller()

	if visual_controller == null:
		return

	if visual_controller.has_method("play_damage_flash"):
		visual_controller.call("play_damage_flash")

## Atualiza animação/estado visual com movimento e vida atuais.
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
			or player_body_slide_velocity.length() > 0.001
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

## Mantém direção visual voltada à Gaia, separada da velocidade física final.
func _get_visual_movement_direction() -> Vector2:
	if target_node != null and is_instance_valid(target_node):
		var to_target: Vector2 = target_node.global_position - global_position

		if to_target.length() > 0.001:
			visual_chase_direction = to_target.normalized()

	return visual_chase_direction

## Localiza visual controller por path, fallback direto ou busca recursiva.
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

## Resolve alvo por NodePath ou grupo configurado.
func _resolve_target() -> Node2D:
	if target_path != NodePath():
		var configured_target: Node = get_node_or_null(target_path)

		if configured_target is Node2D:
			return configured_target as Node2D

	var group_target: Node2D = _find_first_node2d_in_group(target_group_name)

	if group_target != null:
		return group_target

	return null

## Retorna o primeiro Node2D encontrado em um grupo.
func _find_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null

## Formata breakdown do DamageResolver para logs técnicos.
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

## Retorna estado interno do inimigo para DebugOverlay/ferramentas.
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
		"received_knockback_chase_weight": received_knockback_chase_weight,
		"player_body_slide_enabled": player_body_slide_enabled,
		"player_body_slide_power": player_body_slide_power,
		"player_body_slide_velocity_per_power": player_body_slide_velocity_per_power,
		"player_body_slide_max_velocity": player_body_slide_max_velocity,
		"player_body_slide_away_influence": player_body_slide_away_influence,
		"player_body_slide_velocity": player_body_slide_velocity,
		"player_body_slide_decay_per_second": player_body_slide_decay_per_second,
	}

## Aplica decaimento da velocidade de slide ao redor do player.
func _update_player_body_slide_velocity(delta: float) -> void:
	if player_body_slide_velocity.length() <= 0.001:
		player_body_slide_velocity = Vector2.ZERO
		return

	var decay_amount: float = player_body_slide_decay_per_second * delta
	player_body_slide_velocity = player_body_slide_velocity.move_toward(
		Vector2.ZERO,
		decay_amount
	)
