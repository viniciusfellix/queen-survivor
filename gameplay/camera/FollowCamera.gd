## Câmera principal utilizada durante a run.
##
## Responsabilidades:
## - localizar ou receber manualmente o player que deve ser seguido;
## - acompanhar sua posição com suavização configurável;
## - permitir reposicionamento imediato ao iniciar a cena.
##
## A câmera não altera movimento nem estado do player.
extends Camera2D

@export_group("Target")

## Define se a câmera deve acompanhar o target atual.
@export var follow_enabled: bool = true

## Caminho opcional para um target configurado diretamente na cena.
##
## Quando vazio ou inválido, a câmera procura o primeiro Node2D
## registrado no grupo indicado por `target_group_name`.
@export var target_path: NodePath

## Grupo utilizado como fallback para localizar o player.
@export var target_group_name: String = "player"

@export_group("Movement")

## Intensidade da interpolação aplicada ao acompanhamento.
##
## Valores maiores aproximam a câmera mais rapidamente do target.
## Valores iguais ou menores que zero desativam suavização.
@export var follow_smoothing: float = 12.0

## Deslocamento fixo aplicado à posição acompanhada.
@export var position_offset: Vector2 = Vector2.ZERO

## Define se a câmera deve ir imediatamente até o target ao encontrá-lo.
@export var snap_to_target_on_ready: bool = true

## Referência atual do Node2D acompanhado pela câmera.
var target_node: Node2D = null

## Ativa a câmera e tenta resolver um target já existente na cena.
func _ready() -> void:
	enabled = true
	make_current()

	target_node = _resolve_target()

	if target_node != null and snap_to_target_on_ready:
		global_position = target_node.global_position + position_offset

## Atualiza o acompanhamento do target a cada frame.
##
## Caso o player ainda não exista no momento do `_ready()`,
## tenta localizá-lo novamente durante runtime.
func _process(delta: float) -> void:
	if not follow_enabled:
		return

	if target_node == null:
		target_node = _resolve_target()

		if target_node == null:
			return

	_update_follow(delta)

## Define explicitamente um novo target para a câmera.
##
## A cena de teste utiliza este método após instanciar a Gaia,
## evitando depender apenas da busca automática por grupo.
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

## Remove a referência atual do target acompanhado.
func clear_target() -> void:
	target_node = null

## Move a câmera em direção à posição desejada do target.
##
## Com suavização ativa, utiliza interpolação para evitar movimento rígido.
## Sem suavização, aplica imediatamente a posição final.
func _update_follow(delta: float) -> void:
	if target_node == null:
		return

	var desired_position: Vector2 = target_node.global_position + position_offset

	if follow_smoothing <= 0.0:
		global_position = desired_position
		return

	var weight: float = clamp(delta * follow_smoothing, 0.0, 1.0)
	global_position = global_position.lerp(desired_position, weight)

## Resolve o target inicial por caminho configurado ou grupo.
func _resolve_target() -> Node2D:
	if target_path != NodePath():
		var configured_target: Node = get_node_or_null(target_path)

		if configured_target is Node2D:
			return configured_target as Node2D

	var group_target: Node2D = _find_first_node2d_in_group(target_group_name)

	if group_target != null:
		return group_target

	return null

## Retorna o primeiro Node2D encontrado em um grupo da árvore atual.
func _find_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null
