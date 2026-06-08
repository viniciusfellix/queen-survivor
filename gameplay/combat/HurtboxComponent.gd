## Componente de hurtbox reutilizável.
##
## Responsabilidades:
## - construir CollisionShape2D runtime a partir de HurtboxAreaDefinition;
## - expor uma área vulnerável detectável por hitboxes;
## - resolver o node que receberá o dano;
## - permitir ativar/desativar a hurtbox durante morte, encerramento ou estados especiais.
##
## Importante:
## Hurtbox recebe detecção; quem processa dano é o receiver.
extends Area2D
class_name HurtboxComponent

@export_group("Definition")

@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export var damage_receiver_path: NodePath = NodePath("..")

@export_group("Collision Filter")

@export_range(1, 32, 1) var collision_layer_number: int = 5

@export var configure_collision_filter_on_ready: bool = true

@export_group("Diagnostics")

@export var log_configuration: bool = false

## Receiver real que receberá chamadas de dano.
var damage_receiver: Node = null
var runtime_shape_nodes: Array[CollisionShape2D] = []
var is_active: bool = true

## Inicializa grupo, monitoramento e shapes iniciais da hurtbox.
func _ready() -> void:
	add_to_group("hurtbox")

	monitoring = false
	monitorable = true

	if configure_collision_filter_on_ready:
		_configure_collision_filter()

	damage_receiver = _resolve_damage_receiver()

	if not hurtbox_areas.is_empty():
		rebuild_runtime_shapes()

## Hook do pool: deixa a hurtbox inerte até o setup do próximo uso.
func _on_pool_acquire() -> void:
	damage_receiver = null
	set_hurtbox_active(false)

## Hook do pool: limpa receiver e desliga a hurtbox ao devolver ao pool.
func _on_pool_release() -> void:
	damage_receiver = null
	set_hurtbox_active(false)

## Configura áreas vulneráveis e receiver de dano em runtime.
func setup(
	p_hurtbox_areas: Array[HurtboxAreaDefinition],
	p_damage_receiver: Node = null
) -> void:
	if p_damage_receiver != null:
		damage_receiver = p_damage_receiver
	else:
		damage_receiver = _resolve_damage_receiver()

	hurtbox_areas.clear()

	for hurtbox_area: HurtboxAreaDefinition in p_hurtbox_areas:
		if hurtbox_area == null:
			continue

		if not hurtbox_area.is_valid_definition():
			continue

		var duplicated_area: HurtboxAreaDefinition = (
			hurtbox_area.duplicate(true) as HurtboxAreaDefinition
		)

		hurtbox_areas.append(duplicated_area)

	rebuild_runtime_shapes()
	set_hurtbox_active(true)

	if log_configuration:
		DeveloperAuditLogger.log_combat(
			"Hurtbox configurada: receiver=%s areas=%s" % [
				_get_receiver_debug_name(),
				_get_areas_debug_summary()
			],
			"HurtboxComponent",
			{
				"receiver": _get_receiver_debug_name(),
				"areas": _get_areas_debug_summary()
			}
		)

## Reconstrói CollisionShape2D runtime a partir de HurtboxAreaDefinition.
func rebuild_runtime_shapes() -> void:
	_clear_runtime_shapes()

	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null or not hurtbox_area.is_valid_definition():
			continue

		var runtime_shape: Shape2D = hurtbox_area.build_runtime_shape()

		if runtime_shape == null:
			continue

		var shape_node: CollisionShape2D = CollisionShape2D.new()
		shape_node.name = "RuntimeHurtboxShape_%s" % str(runtime_shape_nodes.size())
		shape_node.shape = runtime_shape
		shape_node.position = hurtbox_area.local_offset
		shape_node.rotation_degrees = hurtbox_area.local_rotation_degrees

		add_child(shape_node)
		runtime_shape_nodes.append(shape_node)

	if runtime_shape_nodes.is_empty() and log_configuration:
		push_warning("[HurtboxComponent] Nenhuma shape válida foi construída.")

## Retorna o node que deve receber o dano detectado nesta hurtbox.
func get_damage_receiver() -> Node:
	return damage_receiver

## Verifica se a hurtbox e o receiver estão aptos a receber dano.
func can_receive_damage() -> bool:
	return (
		is_active
		and damage_receiver != null
		and is_instance_valid(damage_receiver)
		and damage_receiver.has_method("receive_damage")
	)

## Ativa/desativa a hurtbox sem remover suas shapes.
func set_hurtbox_active(should_be_active: bool) -> void:
	is_active = should_be_active
	set_deferred("monitorable", should_be_active)

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.set_deferred("disabled", not should_be_active)

## Configura layer da hurtbox conforme collision_layer_number.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(collision_layer_number, true)

## Resolve o receiver pelo NodePath configurado.
func _resolve_damage_receiver() -> Node:
	if damage_receiver_path != NodePath():
		var configured_receiver: Node = get_node_or_null(damage_receiver_path)

		if configured_receiver != null:
			return configured_receiver

	return get_parent()

## Remove shapes runtime geradas anteriormente.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()

## Retorna nome amigável do receiver para logs.
func _get_receiver_debug_name() -> String:
	if damage_receiver == null:
		return "none"

	return damage_receiver.name

## Retorna resumo textual das áreas vulneráveis configuradas.
func _get_areas_debug_summary() -> String:
	var summaries: Array[String] = []

	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		summaries.append(hurtbox_area.get_debug_summary())

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
