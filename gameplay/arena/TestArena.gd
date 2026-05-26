## Visual técnico da arena infinita utilizada no protótipo.
##
## Desenha uma grade de referência e um marcador de origem para facilitar
## testes de movimentação, spawn, câmera, alcance e orientação de ataques.
##
## Este script não define colisões, limites de mapa ou regras de gameplay.
extends Node2D

## Define se a grade técnica deve ser desenhada.
@export var draw_debug_grid: bool = true

## Distância em pixels entre linhas consecutivas da grade.
@export var grid_size: int = 128

## Extensão desenhada da grade para cada direção a partir da origem.
@export var grid_extent: int = 4096

## Define se o marcador circular da origem do mapa deve ser exibido.
@export var draw_origin_marker: bool = true

## Raio visual do marcador desenhado na coordenada `(0, 0)`.
@export var origin_marker_radius: float = 10.0

## Valida configurações visuais básicas e agenda o desenho inicial da arena.
func _ready() -> void:
	if draw_debug_grid and grid_size <= 0:
		push_warning("[TestArena] grid_size precisa ser maior que zero para desenhar a grade.")

	if draw_debug_grid and grid_extent <= 0:
		push_warning("[TestArena] grid_extent precisa ser maior que zero para desenhar a grade.")

	if draw_origin_marker and origin_marker_radius <= 0.0:
		push_warning("[TestArena] origin_marker_radius precisa ser maior que zero para desenhar o marcador.")

	queue_redraw()

## Desenha os elementos técnicos habilitados independentemente.
##
## A grade e o marcador possuem toggles separados para permitir testes
## com a arena visualmente limpa sem perder referência da origem.
func _draw() -> void:
	if draw_debug_grid:
		_draw_grid()

	if draw_origin_marker:
		_draw_origin_marker()

## Desenha a grade técnica da arena e destaca seus eixos centrais.
##
## Linhas principais aparecem a cada quatro células para facilitar
## leitura visual de distâncias maiores durante os testes.
func _draw_grid() -> void:
	if grid_size <= 0 or grid_extent <= 0:
		return

	var minor_color: Color = Color(0.18, 0.18, 0.18, 1.0)
	var major_color: Color = Color(0.32, 0.32, 0.32, 1.0)
	var origin_x_color: Color = Color(0.35, 0.15, 0.15, 1.0)
	var origin_y_color: Color = Color(0.15, 0.35, 0.15, 1.0)

	var start_position: int = -grid_extent
	var end_position: int = grid_extent
	var major_grid_size: int = grid_size * 4

	for x: int in range(start_position, end_position + grid_size, grid_size):
		var vertical_color: Color = major_color

		if x % major_grid_size != 0:
			vertical_color = minor_color

		draw_line(
			Vector2(float(x), float(start_position)),
			Vector2(float(x), float(end_position)),
			vertical_color,
			1.0
		)

	for y: int in range(start_position, end_position + grid_size, grid_size):
		var horizontal_color: Color = major_color

		if y % major_grid_size != 0:
			horizontal_color = minor_color

		draw_line(
			Vector2(float(start_position), float(y)),
			Vector2(float(end_position), float(y)),
			horizontal_color,
			1.0
		)

	draw_line(
		Vector2(float(start_position), 0.0),
		Vector2(float(end_position), 0.0),
		origin_y_color,
		3.0
	)

	draw_line(
		Vector2(0.0, float(start_position)),
		Vector2(0.0, float(end_position)),
		origin_x_color,
		3.0
	)

## Desenha o marcador circular da origem absoluta da arena.
func _draw_origin_marker() -> void:
	if origin_marker_radius <= 0.0:
		return

	draw_circle(Vector2.ZERO, origin_marker_radius, Color.WHITE)
