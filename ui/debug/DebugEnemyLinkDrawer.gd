## Ferramenta visual de debug que desenha linhas entre Gaia e inimigos.
##
## Responsabilidades:
## - localizar o player por grupo;
## - localizar inimigos por grupo;
## - desenhar linhas em tela entre player e inimigos vivos;
## - exibir marcadores opcionais;
## - funcionar apenas quando habilitada pelo DebugOverlay/Inspector.
##
## Importante:
## Este script é somente visual/debug.
## Ele não altera IA, movimento, combate, hitbox, hurtbox ou spawn.
extends Node2D
class_name DebugEnemyLinkDrawer

## Define se as linhas estão habilitadas.
var links_enabled: bool = false

## Grupo usado para localizar o player/Gaia.
var player_group_name: String = "player"

## Grupo usado para localizar inimigos.
var enemy_group_name: String = "enemy"

## Cor das linhas e marcadores.
var link_color: Color = Color(1.0, 0.18, 0.18, 0.70)

## Espessura da linha.
var link_width: float = 2.0

## Define se desenha círculos nos pontos de player/inimigos.
var show_markers: bool = false

## Raio do marcador do player.
var player_marker_radius: float = 5.0

## Raio do marcador dos inimigos.
var enemy_marker_radius: float = 4.0

## Inicializa a ferramenta desligada.
func _ready() -> void:
	z_index = -10
	set_process(false)
	visible = false

## Atualiza desenho enquanto a ferramenta estiver ativa.
func _process(_delta: float) -> void:
	if not links_enabled:
		return

	queue_redraw()

## Configura a ferramenta a partir de outro script, normalmente DebugOverlay.
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

	if was_enabled != links_enabled:
		queue_redraw()

## Desenha linhas do player até os inimigos ativos.
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

## Decide se um inimigo deve ser desenhado.
##
## Se o inimigo expõe get_debug_data() com is_alive=false, ele é ignorado.
## Caso não exponha esse método, assume que pode ser desenhado.
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

## Converte posição de mundo em posição de tela/canvas atual.
##
## Necessário porque o desenho do Node2D acontece em coordenadas de canvas.
func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()

	return canvas_transform * world_position

## Retorna o primeiro Node2D encontrado em determinado grupo.
func _get_first_node2d_in_group(group_name: String) -> Node2D:
	if group_name.strip_edges() == "":
		return null

	var nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)

	for node: Node in nodes:
		if node is Node2D:
			return node as Node2D

	return null
