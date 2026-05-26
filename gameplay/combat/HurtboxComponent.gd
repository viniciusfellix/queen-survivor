## Componente runtime que representa uma região vulnerável.
##
## Responsabilidades:
## - funcionar como Area2D detectável por hitboxes;
## - construir CollisionShape2D runtime a partir de resources;
## - identificar o node dono que realmente recebe o dano;
## - ativar ou desativar a vulnerabilidade.
##
## Este componente não calcula dano, HP, morte, XP ou drop.
## Essas responsabilidades continuam no receiver, como:
## - EnemyBase, em hurtboxes de inimigos;
## - PlayerController, em hurtboxes de Queens.
extends Area2D
class_name HurtboxComponent

@export_group("Definition")

## Configuração local opcional.
##
## No EnemyBase atual, essas áreas serão fornecidas por EnemyDefinition
## durante o setup do inimigo.
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

## Caminho relativo para o node que possui receive_damage().
##
## Como a Hurtbox será filha direta de EnemyBase, o padrão é "..".
@export var damage_receiver_path: NodePath = NodePath("..")

@export_group("Collision Filter")

## Número da physics layer utilizada por esta hurtbox.
##
## Convenções atuais:
## - Layer 5 = EnemyHurtbox;
## - Layer 7 = PlayerHurtbox.
##
## O valor deve ser configurado no node conforme seu proprietário.
@export_range(1, 32, 1) var collision_layer_number: int = 5

## Quando verdadeiro, o script configura layer e mask automaticamente.
@export var configure_collision_filter_on_ready: bool = true

@export_group("Diagnostics")

@export var log_configuration: bool = false

var damage_receiver: Node = null
var runtime_shape_nodes: Array[CollisionShape2D] = []
var is_active: bool = true

func _ready() -> void:
	add_to_group("hurtbox")

	monitoring = false
	monitorable = true

	if configure_collision_filter_on_ready:
		_configure_collision_filter()

	damage_receiver = _resolve_damage_receiver()

	if not hurtbox_areas.is_empty():
		rebuild_runtime_shapes()

## Recebe áreas configuradas pelo dono da hurtbox.
##
## As definitions são duplicadas para impedir alterações indesejadas
## nos resources salvos durante a execução da run.
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

## Remove shapes anteriores e cria novas CollisionShape2D runtime.
##
## Cada shape criada permanece filha direta deste Area2D, conforme
## o modelo físico esperado pela Godot.
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

## Retorna o node que realmente possui a lógica de receber dano.
func get_damage_receiver() -> Node:
	return damage_receiver

## Indica se a hitbox pode encaminhar dano para esta hurtbox.
func can_receive_damage() -> bool:
	return (
		is_active
		and damage_receiver != null
		and is_instance_valid(damage_receiver)
		and damage_receiver.has_method("receive_damage")
	)

## Habilita ou desabilita a hurtbox.
##
## Ao morrer, o inimigo desativa imediatamente seu estado lógico.
## A desativação física das shapes é deferred para evitar alteração
## de física durante o processamento de colisões.
func set_hurtbox_active(should_be_active: bool) -> void:
	is_active = should_be_active
	set_deferred("monitorable", should_be_active)

	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		shape_node.set_deferred("disabled", not should_be_active)

## Define esta Area2D somente na layer de hurtbox configurada.
##
## A hurtbox não monitora ataques; a hitbox ofensiva é quem monitora
## a EnemyHurtbox por meio de sua collision mask.
func _configure_collision_filter() -> void:
	collision_layer = 0
	collision_mask = 0

	set_collision_layer_value(collision_layer_number, true)

## Localiza o receiver configurado, normalmente o EnemyBase pai.
func _resolve_damage_receiver() -> Node:
	if damage_receiver_path != NodePath():
		var configured_receiver: Node = get_node_or_null(damage_receiver_path)

		if configured_receiver != null:
			return configured_receiver

	return get_parent()

## Remove todas as shapes runtime construídas anteriormente.
func _clear_runtime_shapes() -> void:
	for shape_node: CollisionShape2D in runtime_shape_nodes:
		if shape_node == null or not is_instance_valid(shape_node):
			continue

		remove_child(shape_node)
		shape_node.queue_free()

	runtime_shape_nodes.clear()

## Retorna nome seguro do receiver para logs.
func _get_receiver_debug_name() -> String:
	if damage_receiver == null:
		return "none"

	return damage_receiver.name

## Retorna descrição compacta das shapes configuradas.
func _get_areas_debug_summary() -> String:
	var summaries: Array[String] = []

	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		summaries.append(hurtbox_area.get_debug_summary())

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
