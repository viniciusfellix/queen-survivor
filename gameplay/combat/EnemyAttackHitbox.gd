## Área ofensiva runtime usada por inimigos.
##
## Responsabilidades:
## - construir shapes de ataque a partir de EnemyAttackDefinition;
## - detectar PlayerHurtbox;
## - respeitar delay inicial e intervalo entre hits;
## - gerar DamagePayload para o receiver;
## - evitar dano enquanto a run está bloqueada/encerrando;
## - manter BodyCollision separado do sistema de dano.
##
## Exemplo atual:
## - ataque corporal do Goblin contra a Gaia.
extends Area2D
class_name EnemyAttackHitbox

@export_group("Collision Filter")

@export_range(1, 32, 1) var collision_layer_number: int = 6

@export_range(1, 32, 1) var target_hurtbox_layer_number: int = 7

@export var configure_collision_filter_on_ready: bool = true

@export_group("Diagnostics")

@export var log_configuration: bool = false

@export var log_successful_hits: bool = true

## Definition e origem usadas por esta instância runtime.
var runtime_definition: EnemyAttackDefinition = null
var source_node: Node = null
var source_id: String = ""

## Shapes geradas em runtime e cooldowns por receiver atingido.
var runtime_shape_nodes: Array[CollisionShape2D] = []
var receiver_cooldowns: Dictionary = {}

## Controle de tempo interno e estado de ativação.
var elapsed_seconds: float = 0.0
var is_active: bool = false
var is_configured: bool = false

## Inicializa grupo, modo de monitoramento e filtro de colisão da hitbox inimiga.
func _ready() -> void:
	add_to_group("enemy_attack_hitbox")

	monitoring = false
	monitorable = false

	if configure_collision_filter_on_ready:
		_configure_collision_filter()

## Atualiza timing, cooldowns por receiver e tenta aplicar dano quando ativo.
func _physics_process(delta: float) -> void:
	if not is_configured or not is_active:
		return

	if RunQuery.is_gameplay_blocked(get_tree()):
		return

	elapsed_seconds += delta

	_update_receiver_cooldowns(delta)

	if runtime_definition == null:
		return

	if elapsed_seconds < runtime_definition.start_delay_seconds:
		return

	_try_damage_overlapping_hurtboxes()

## Configura esta hitbox com definition, fonte e id do inimigo.
func setup(
	p_attack_definition: EnemyAttackDefinition,
	p_source_node: Node,
	p_source_id: String = ""
) -> void:
	source_node = p_source_node

	if p_attack_definition == null or not p_attack_definition.is_valid_definition():
		runtime_definition = null
		source_id = ""
		is_configured = false
		_clear_runtime_shapes()
		set_attack_active(false)
		push_warning("[EnemyAttackHitbox] Definition de ataque ausente ou inválida.")
		return

	runtime_definition = p_attack_definition.duplicate(true) as EnemyAttackDefinition

	if p_source_id.strip_edges() != "":
		source_id = p_source_id
	else:
		source_id = runtime_definition.id

	elapsed_seconds = 0.0
	receiver_cooldowns.clear()

	rebuild_runtime_shapes()

	is_configured = not runtime_shape_nodes.is_empty()
	set_attack_active(is_configured)

	if log_configuration:
		DeveloperAuditLogger.log_combat(
			"Hitbox configurada: source=%s attack=%s damage=%s type=%s interval=%s delay=%s areas=%s" % [
				source_id,
				runtime_definition.id,
				str(runtime_definition.raw_damage),
				runtime_definition.damage_type,
				str(runtime_definition.hit_interval_seconds),
				str(runtime_definition.start_delay_seconds),
				runtime_definition.get_areas_debug_summary()
			],
			"EnemyAttackHitbox",
			{
				"source_id": source_id,
				"attack_id": runtime_definition.id,
				"raw_damage": runtime_definition.raw_damage,
				"damage_type": runtime_definition.damage_type,
				"hit_interval_seconds": runtime_definition.hit_interval_seconds,
				"start_delay_seconds": runtime_definition.start_delay_seconds,
				"areas": runtime_definition.get_areas_debug_summary()
			}
		)

## Reconstrói shapes runtime a partir das AttackAreaDefinitions configuradas.
func rebuild_runtime_shapes() -> void:
	_clear_runtime_shapes()

	if runtime_definition == null:
		return

	for attack_area: AttackAreaDefinition in runtime_definition.attack_areas:
		if attack_area == null or not attack_area.is_valid_definition():
			continue

		var runtime_shape: Shape2D = attack_area.build_runtime_shape()

		if runtime_shape == null:
			continue

		var shape_node: CollisionShape2D = CollisionShape2D.new()
		shape_node.name = "RuntimeEnemyAttackShape_%s" % str(runtime_shape_nodes.size())
		shape_node.shape = runtime_shape
		shape_node.position = attack_area.local_offset
		shape_node.rotation_degrees = attack_area.local_rotation_degrees

		add_child(shape_node)
		runtime_shape_nodes.append(shape_node)

	if runtime_shape_nodes.is_empty():
		push_warning("[EnemyAttackHitbox] Nenhuma shape ofensiva válida foi construída.")

## Ativa ou desativa a detecção ofensiva desta hitbox.
func set_attack_active(should_be_active: bool) -> void:
	is_active = should_be_active

	set_deferred("monitoring", should_be_active)

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.set_deferred("disabled", not should_be_active)

	if not should_be_active:
		receiver_cooldowns.clear()

## Verifica hurtboxes sobrepostas e aplica dano respeitando cooldown por receiver.
func _try_damage_overlapping_hurtboxes() -> void:
	if runtime_definition == null:
		return

	for overlapping_area: Area2D in get_overlapping_areas():
		if not overlapping_area is HurtboxComponent:
			continue

		var hurtbox: HurtboxComponent = overlapping_area as HurtboxComponent

		if not hurtbox.can_receive_damage():
			continue

		var receiver: Node = hurtbox.get_damage_receiver()

		if receiver == null or receiver == source_node:
			continue

		var receiver_instance_id: int = int(receiver.get_instance_id())
		var remaining_cooldown: float = float(
			receiver_cooldowns.get(receiver_instance_id, 0.0)
		)

		if remaining_cooldown > 0.0:
			continue

		var payload: DamagePayload = runtime_definition.build_damage_payload(
			source_node,
			source_id
		)

		var final_damage_variant: Variant = receiver.call("receive_damage", payload)
		var final_damage: int = _variant_to_damage(final_damage_variant)

		if final_damage <= 0:
			continue

		receiver_cooldowns[receiver_instance_id] = (
			runtime_definition.hit_interval_seconds
		)

		if log_successful_hits:
			DeveloperAuditLogger.log_combat(
				"PlayerHurtbox atingida: receiver=%s attack=%s raw=%s final=%s areas=%s" % [
					receiver.name,
					runtime_definition.id,
					str(runtime_definition.raw_damage),
					str(final_damage),
					runtime_definition.get_areas_debug_summary()
				],
				"EnemyAttackHitbox",
				{
					"receiver": receiver.name,
					"attack_id": runtime_definition.id,
					"raw_damage": runtime_definition.raw_damage,
					"final_damage": final_damage,
					"areas": runtime_definition.get_areas_debug_summary()
				}
			)

## Reduz os cooldowns individuais de receivers atingidos recentemente.
func _update_receiver_cooldowns(delta: float) -> void:
	for receiver_id_variant: Variant in receiver_cooldowns.keys():
		var remaining_seconds: float = (
			float(receiver_cooldowns.get(receiver_id_variant, 0.0)) - delta
		)

		if remaining_seconds <= 0.0:
			receiver_cooldowns.erase(receiver_id_variant)
		else:
			receiver_cooldowns[receiver_id_variant] = remaining_seconds

## Configura layer/mask conforme números definidos no Inspector.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(collision_layer_number, true)
	set_collision_mask_value(target_hurtbox_layer_number, true)

## Remove CollisionShape2D criadas em runtime.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()

## Converte retorno do receiver em inteiro de dano confirmado.
func _variant_to_damage(value: Variant) -> int:
	if value is int:
		return int(value)

	if value is float:
		return int(value)

	return 0

## Retorna dados compactos para debug/auditoria.
func get_debug_data() -> Dictionary:
	return {
		"is_configured": is_configured,
		"is_active": is_active,
		"source_id": source_id,
		"has_runtime_definition": runtime_definition != null,
		"attack_id": runtime_definition.id if runtime_definition != null else "",
		"areas": runtime_definition.get_areas_debug_summary() if runtime_definition != null else "none",
		"elapsed_seconds": elapsed_seconds,
		"runtime_shape_count": runtime_shape_nodes.size()
	}
