## Câmera de acompanhamento do player.
##
## Responsabilidades:
## - localizar um alvo por NodePath ou grupo;
## - seguir esse alvo com suavização configurável;
## - aplicar offset visual;
## - permitir snap inicial para evitar transição estranha no começo da run.
##
## Importante:
## Esta câmera não altera gameplay. Ela apenas acompanha visualmente a Gaia.
extends Camera2D

@export_group("Target")

@export var follow_enabled: bool = true

@export var target_path: NodePath

@export var target_group_name: String = "player"

@export_group("Movement")

@export var follow_smoothing: float = 12.0

@export var position_offset: Vector2 = Vector2.ZERO

@export var snap_to_target_on_ready: bool = true

var target_node: Node2D = null

## Ativa a câmera, torna-a atual e tenta resolver o alvo inicial.
func _ready() -> void:
	enabled = true
	make_current()

	target_node = _resolve_target()

	if target_node != null and snap_to_target_on_ready:
		global_position = target_node.global_position + position_offset

## Atualiza a câmera a cada frame enquanto o follow estiver habilitado.
func _process(delta: float) -> void:
	if not follow_enabled:
		return

	if target_node == null:
		target_node = _resolve_target()

		if target_node == null:
			return

	_update_follow(delta)

## Define explicitamente o alvo da câmera e aplica snap inicial se configurado.
func set_target(new_target: Node2D) -> void:
	target_node = new_target

	if target_node == null:
		return

	DeveloperAuditLogger.log_scene(
		"Target definido: %s" % target_node.name,
		"FollowCamera",
		{
			"target_name": target_node.name
		}
	)

	if snap_to_target_on_ready:
		global_position = target_node.global_position + position_offset

## Remove o alvo atual. A câmera poderá tentar resolver outro alvo depois.
func clear_target() -> void:
	target_node = null

## Move a câmera em direção ao alvo usando suavização exponencial.
func _update_follow(delta: float) -> void:
	if target_node == null:
		return

	var desired_position: Vector2 = target_node.global_position + position_offset

	if follow_smoothing <= 0.0:
		global_position = desired_position
		return

	var weight: float = clamp(delta * follow_smoothing, 0.0, 1.0)
	global_position = global_position.lerp(desired_position, weight)

## Resolve o alvo por NodePath configurado ou pelo primeiro Node2D no grupo.
func _resolve_target() -> Node2D:
	if target_path != NodePath():
		var configured_target: Node = get_node_or_null(target_path)

		if configured_target is Node2D:
			return configured_target as Node2D

	var group_target: Node2D = _find_first_node2d_in_group(target_group_name)

	if group_target != null:
		return group_target

	return null

## Busca o primeiro Node2D pertencente ao grupo informado.
func _find_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null
