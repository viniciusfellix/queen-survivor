## Definição geométrica base compartilhada por hitboxes e hurtboxes.
##
## Responsabilidades:
## - armazenar formato, offset e rotação local;
## - validar shapes suportadas;
## - construir cópias runtime escaladas;
## - fornecer resumo técnico para logs.
##
## Este resource não aplica dano e não detecta colisões sozinho.
extends Resource
class_name CombatShapeDefinition

## Identificador técnico da área.
##
## Exemplos:
## - attack_area_gaia_initial_primary
## - hurtbox_area_enemy_chaser_basic_body
@export var id: String = ""

## Permite desabilitar temporariamente a área sem removê-la do resource.
@export var enabled: bool = true

## Geometria da área.
##
## Formatos suportados:
## - CircleShape2D;
## - RectangleShape2D;
## - CapsuleShape2D;
## - ConvexPolygonShape2D.
@export var shape: Shape2D

## Deslocamento da shape em relação ao centro do Area2D dono.
@export var local_offset: Vector2 = Vector2.ZERO

## Rotação adicional da shape dentro da área.
@export_range(-180.0, 180.0, 0.1) var local_rotation_degrees: float = 0.0

## Verifica se a definição possui identificação e shape utilizável.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and enabled
		and shape != null
		and is_shape_supported()
	)

## Indica se a shape configurada já possui suporte runtime no projeto.
func is_shape_supported() -> bool:
	return (
		shape is CircleShape2D
		or shape is RectangleShape2D
		or shape is CapsuleShape2D
		or shape is ConvexPolygonShape2D
	)

## Cria uma cópia da shape para utilização runtime.
##
## O multiplicador é aplicado às dimensões da cópia, sem alterar
## o resource original salvo no projeto.
func build_runtime_shape(scale_multiplier: float = 1.0) -> Shape2D:
	if not is_valid_definition():
		return null

	var safe_scale: float = max(0.01, scale_multiplier)
	var runtime_shape: Shape2D = shape.duplicate(true) as Shape2D

	if runtime_shape is CircleShape2D:
		var circle_shape: CircleShape2D = runtime_shape as CircleShape2D
		circle_shape.radius *= safe_scale

	elif runtime_shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = runtime_shape as RectangleShape2D
		rectangle_shape.size *= safe_scale

	elif runtime_shape is CapsuleShape2D:
		var capsule_shape: CapsuleShape2D = runtime_shape as CapsuleShape2D
		capsule_shape.radius *= safe_scale
		capsule_shape.height *= safe_scale

	elif runtime_shape is ConvexPolygonShape2D:
		var polygon_shape: ConvexPolygonShape2D = runtime_shape as ConvexPolygonShape2D
		var scaled_points: PackedVector2Array = PackedVector2Array()

		for point: Vector2 in polygon_shape.points:
			scaled_points.append(point * safe_scale)

		polygon_shape.points = scaled_points

	return runtime_shape

## Retorna o raio escalado quando a shape for circular.
func get_scaled_circle_radius(scale_multiplier: float = 1.0) -> float:
	if not shape is CircleShape2D:
		return 0.0

	var circle_shape: CircleShape2D = shape as CircleShape2D

	return circle_shape.radius * max(0.01, scale_multiplier)

## Retorna o tamanho escalado quando a shape for retangular.
func get_scaled_rectangle_size(scale_multiplier: float = 1.0) -> Vector2:
	if not shape is RectangleShape2D:
		return Vector2.ZERO

	var rectangle_shape: RectangleShape2D = shape as RectangleShape2D

	return rectangle_shape.size * max(0.01, scale_multiplier)

## Retorna nome compacto da geometria para logs.
func get_shape_debug_name() -> String:
	if shape is CircleShape2D:
		return "circle"

	if shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = shape as RectangleShape2D

		if is_equal_approx(rectangle_shape.size.x, rectangle_shape.size.y):
			return "square"

		return "rectangle"

	if shape is CapsuleShape2D:
		return "capsule"

	if shape is ConvexPolygonShape2D:
		return "convex_polygon"

	return "unsupported"

## Retorna resumo técnico da área para logs de debug/audit.
func get_debug_summary(scale_multiplier: float = 1.0) -> String:
	var runtime_shape: Shape2D = build_runtime_shape(scale_multiplier)

	if runtime_shape == null:
		return "%s:invalid" % id

	if runtime_shape is CircleShape2D:
		var circle_shape: CircleShape2D = runtime_shape as CircleShape2D

		return "%s:%s radius=%s offset=%s" % [
			id,
			get_shape_debug_name(),
			str(circle_shape.radius),
			str(local_offset)
		]

	if runtime_shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = runtime_shape as RectangleShape2D

		return "%s:%s size=%s offset=%s" % [
			id,
			get_shape_debug_name(),
			str(rectangle_shape.size),
			str(local_offset)
		]

	if runtime_shape is CapsuleShape2D:
		var capsule_shape: CapsuleShape2D = runtime_shape as CapsuleShape2D

		return "%s:%s radius=%s height=%s offset=%s" % [
			id,
			get_shape_debug_name(),
			str(capsule_shape.radius),
			str(capsule_shape.height),
			str(local_offset)
		]

	if runtime_shape is ConvexPolygonShape2D:
		var polygon_shape: ConvexPolygonShape2D = runtime_shape as ConvexPolygonShape2D

		return "%s:%s points=%s offset=%s" % [
			id,
			get_shape_debug_name(),
			str(polygon_shape.points.size()),
			str(local_offset)
		]

	return "%s:unsupported" % id
