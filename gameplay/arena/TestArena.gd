extends Node2D

@export var draw_debug_grid: bool = true
@export var grid_size: int = 128
@export var grid_extent: int = 4096

@export var draw_origin_marker: bool = true
@export var origin_marker_radius: float = 10.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if not draw_debug_grid:
		return

	_draw_grid()

	if draw_origin_marker:
		_draw_origin_marker()

func _draw_grid() -> void:
	var minor_color: Color = Color(0.18, 0.18, 0.18, 1.0)
	var major_color: Color = Color(0.32, 0.32, 0.32, 1.0)
	var origin_x_color: Color = Color(0.35, 0.15, 0.15, 1.0)
	var origin_y_color: Color = Color(0.15, 0.35, 0.15, 1.0)

	var start_position: int = -grid_extent
	var end_position: int = grid_extent
	var major_grid_size: int = grid_size * 4

	for x: int in range(start_position, end_position + grid_size, grid_size):
		var vertical_color: Color = major_color

		if major_grid_size != 0 and x % major_grid_size != 0:
			vertical_color = minor_color

		draw_line(
			Vector2(float(x), float(start_position)),
			Vector2(float(x), float(end_position)),
			vertical_color,
			1.0
		)

	for y: int in range(start_position, end_position + grid_size, grid_size):
		var horizontal_color: Color = major_color

		if major_grid_size != 0 and y % major_grid_size != 0:
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

func _draw_origin_marker() -> void:
	draw_circle(Vector2.ZERO, origin_marker_radius, Color.WHITE)
