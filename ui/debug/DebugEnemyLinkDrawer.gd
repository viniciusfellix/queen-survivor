## Drawer visual utilizado pelo DebugOverlay para representar
## conexões entre a Gaia e inimigos ativos durante testes.
##
## Responsabilidades:
## - localizar o player e os inimigos pelos grupos runtime;
## - converter posições mundiais em posições da tela;
## - desenhar linhas técnicas sem alterar comportamento do jogo.
##
## O drawer fica desabilitado por padrão e só processa frames
## quando o DebugOverlay habilitar explicitamente essa visualização.
extends Node2D
class_name DebugEnemyLinkDrawer

## Define se as conexões devem ser desenhadas.
var links_enabled: bool = false

## Grupo utilizado para localizar a Gaia ou player ativo.
var player_group_name: String = "player"

## Grupo utilizado para localizar inimigos existentes na cena.
var enemy_group_name: String = "enemy"

## Cor das linhas desenhadas entre player e inimigos.
var link_color: Color = Color(1.0, 0.18, 0.18, 0.70)

## Espessura das linhas desenhadas.
var link_width: float = 2.0

## Define se pequenos marcadores devem acompanhar as extremidades.
var show_markers: bool = false

## Raio do marcador exibido sobre a posição do player.
var player_marker_radius: float = 5.0

## Raio do marcador exibido sobre cada inimigo.
var enemy_marker_radius: float = 4.0

## Inicia o drawer sem processamento até que a ferramenta seja habilitada.
func _ready() -> void:
	z_index = -10
	set_process(false)
	visible = false

## Solicita novo desenho enquanto a ferramenta estiver habilitada.
##
## A atualização contínua permite acompanhar player, câmera
## e inimigos em movimento sem conexão adicional de signals.
func _process(_delta: float) -> void:
	if not links_enabled:
		return

	queue_redraw()

## Recebe as configurações atualmente definidas no DebugOverlay.
##
## O método também ativa ou desativa o processamento do drawer,
## evitando custo runtime quando a ferramenta não está em uso.
func configure(
	should_enable: bool,
	p_player_group_name: String,
	p_enemy_group_name: String,
	p_link_color: Color,
	p_link_width: float,
	p_show_markers: bool,
	p_player_marker_radius: float,
	p_enemy_marker_radius: float
) -> void:
	var was_enabled: bool = links_enabled

	links_enabled = should_enable
	player_group_name = p_player_group_name
	enemy_group_name = p_enemy_group_name
	link_color = p_link_color
	link_width = max(0.5, p_link_width)
	show_markers = p_show_markers
	player_marker_radius = max(0.0, p_player_marker_radius)
	enemy_marker_radius = max(0.0, p_enemy_marker_radius)

	visible = links_enabled
	set_process(links_enabled)

	# Ao habilitar ou desabilitar, força redesenho imediato para
	# mostrar ou remover linhas sem aguardar o próximo frame útil.
	if was_enabled != links_enabled:
		queue_redraw()

## Desenha linhas entre o player atual e todos os inimigos válidos.
func _draw() -> void:
	if not links_enabled:
		return

	var player_node: Node2D = _get_first_node2d_in_group(player_group_name)

	if player_node == null:
		return

	var player_screen_position: Vector2 = _world_to_screen_position(player_node.global_position)

	if show_markers and player_marker_radius > 0.0:
		draw_circle(player_screen_position, player_marker_radius, link_color)

	var enemies: Array[Node] = get_tree().get_nodes_in_group(enemy_group_name)

	for enemy: Node in enemies:
		if not enemy is Node2D:
			continue

		if enemy == player_node:
			continue

		if not _should_draw_enemy(enemy):
			continue

		var enemy_node: Node2D = enemy as Node2D
		var enemy_screen_position: Vector2 = _world_to_screen_position(enemy_node.global_position)

		draw_line(
			player_screen_position,
			enemy_screen_position,
			link_color,
			link_width,
			true
		)

		if show_markers and enemy_marker_radius > 0.0:
			draw_circle(enemy_screen_position, enemy_marker_radius, link_color)

## Decide se um inimigo deve permanecer visível no desenho técnico.
##
## Quando o inimigo disponibilizar `get_debug_data()` com `is_alive`,
## inimigos mortos são ignorados. Caso contrário, mantém compatibilidade
## e desenha qualquer node ainda pertencente ao grupo `enemy`.
func _should_draw_enemy(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false

	if not enemy.has_method("get_debug_data"):
		return true

	var debug_data_variant: Variant = enemy.call("get_debug_data")

	if not debug_data_variant is Dictionary:
		return true

	var debug_data: Dictionary = debug_data_variant as Dictionary

	if not debug_data.has("is_alive"):
		return true

	return bool(debug_data.get("is_alive", true))

## Converte coordenada mundial para posição visual na viewport atual.
##
## Como o drawer pertence a um CanvasLayer de UI, a posição mundial
## precisa considerar o transform da câmera antes de ser desenhada.
func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()

	return canvas_transform * world_position

## Retorna o primeiro Node2D encontrado em determinado grupo runtime.
func _get_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null
