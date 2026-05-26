## Hitbox ofensiva runtime pertencente a um inimigo.
##
## Responsabilidades:
## - funcionar como Area2D monitorando PlayerHurtbox;
## - construir CollisionShape2D runtime a partir de EnemyAttackDefinition;
## - respeitar delay inicial e intervalo entre impactos;
## - criar DamagePayload e encaminhar dano ao receiver atingido;
## - ativar ou desativar o ataque quando o inimigo nasce ou morre.
##
## Este componente não controla movimento, HP, morte ou animação.
extends Area2D
class_name EnemyAttackHitbox

@export_group("Collision Filter")

## Layer ofensiva desta hitbox.
##
## Convenção atual:
## Layer 6 = EnemyAttackHitbox.
@export_range(1, 32, 1) var collision_layer_number: int = 6

## Layer que esta hitbox deve detectar.
##
## Convenção atual:
## Layer 7 = PlayerHurtbox.
@export_range(1, 32, 1) var target_hurtbox_layer_number: int = 7

## Quando verdadeiro, configura automaticamente layer e mask no _ready().
@export var configure_collision_filter_on_ready: bool = true

@export_group("Diagnostics")

## Ativa log de configuração da hitbox.
@export var log_configuration: bool = false

## Ativa log somente quando um impacto causa dano efetivo.
@export var log_successful_hits: bool = true

var runtime_definition: EnemyAttackDefinition = null
var source_node: Node = null
var source_id: String = ""

var runtime_shape_nodes: Array[CollisionShape2D] = []
var receiver_cooldowns: Dictionary = {}

var elapsed_seconds: float = 0.0
var is_active: bool = false
var is_configured: bool = false

## Inicializa os filtros físicos da hitbox.
##
## A definição de ataque não é carregada diretamente neste node:
## ela é fornecida obrigatoriamente pelo `EnemyBase`, cuja
## `EnemyDefinition` é a fonte oficial dos dados de balanceamento.
func _ready() -> void:
	add_to_group("enemy_attack_hitbox")

	monitoring = false
	monitorable = false

	if configure_collision_filter_on_ready:
		_configure_collision_filter()

## Processa delay, cooldowns e impactos durante gameplay ativo.
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

## Recebe a definição de ataque correspondente ao inimigo atual.
##
## A definition é duplicada para que alterações runtime futuras
## não modifiquem diretamente o resource salvo no projeto.
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

## Reconstrói as CollisionShape2D runtime do ataque atual.
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

## Habilita ou desabilita a área ofensiva.
##
## Utiliza operação deferred para evitar alterações físicas inseguras
## durante callbacks ou passos de colisão.
func set_attack_active(should_be_active: bool) -> void:
	is_active = should_be_active

	set_deferred("monitoring", should_be_active)

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.set_deferred("disabled", not should_be_active)

	if not should_be_active:
		receiver_cooldowns.clear()

## Procura PlayerHurtboxes atualmente sobrepostas e tenta causar dano.
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

		# A invencibilidade temporária da Gaia pode retornar zero.
		# Nesse caso não consumimos o cooldown do ataque.
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

## Reduz os cooldowns individuais dos receivers já atingidos.
func _update_receiver_cooldowns(delta: float) -> void:
	for receiver_id_variant: Variant in receiver_cooldowns.keys():
		var remaining_seconds: float = (
			float(receiver_cooldowns.get(receiver_id_variant, 0.0)) - delta
		)

		if remaining_seconds <= 0.0:
			receiver_cooldowns.erase(receiver_id_variant)
		else:
			receiver_cooldowns[receiver_id_variant] = remaining_seconds

## Define a hitbox apenas na layer ofensiva e detectando PlayerHurtbox.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(collision_layer_number, true)
	set_collision_mask_value(target_hurtbox_layer_number, true)

## Remove shapes runtime anteriormente construídas.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()

## Converte retorno numérico genérico do receiver em dano inteiro.
func _variant_to_damage(value: Variant) -> int:
	if value is int:
		return int(value)

	if value is float:
		return int(value)

	return 0

## Retorna dados técnicos desta hitbox para debugging futuro.
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
