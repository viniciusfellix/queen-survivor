## Texto flutuante usado para feedback visual no mundo/tela.
##
## Responsabilidades:
## - exibir texto temporário, como dano recebido;
## - animar subida;
## - animar escala;
## - animar fade;
## - remover-se automaticamente ao terminar.
##
## Importante:
## Este node é visual.
## Ele não altera dano, HP, run ou save.
extends Label
class_name FloatingCombatText

@export_group("Animation")

## Tempo total da animação.
@export var total_lifetime_seconds: float = 1.00

## Tempo de crescimento inicial.
@export var grow_seconds: float = 0.20

## Distância vertical que o texto sobe.
@export var rise_distance: float = 112.0

## Escala inicial.
@export var start_scale: Vector2 = Vector2(0.78, 0.78)

## Escala máxima após crescimento.
@export var peak_scale: Vector2 = Vector2(1.85, 1.85)

## Escala final antes de sumir.
@export var end_scale: Vector2 = Vector2(0.52, 0.52)

@export_group("Text Style")

## Tamanho da fonte.
@export var font_size: int = 52

## Tamanho do contorno.
@export var outline_size: int = 6

## Cor do contorno.
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.92)

## Evita iniciar animação mais de uma vez.
var animation_started: bool = false

## Configura aparência base do label.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	custom_minimum_size = Vector2(200.0, 90.0)
	size = custom_minimum_size

	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_outline_color", outline_color)
	add_theme_constant_override("outline_size", outline_size)

	scale = start_scale
	self_modulate = Color.WHITE
	pivot_offset = size * 0.5

## Define texto, cor e inicia animação.
func setup(display_text: String, text_color: Color) -> void:
	text = display_text
	visible = true

	add_theme_color_override("font_color", text_color)

	self_modulate = Color.WHITE
	scale = start_scale
	pivot_offset = size * 0.5

	if animation_started:
		return

	animation_started = true
	call_deferred("_play_animation")

## Executa animações de movimento, escala e fade.
func _play_animation() -> void:
	var destination: Vector2 = position + Vector2(0.0, -rise_distance)
	var shrink_seconds: float = max(0.05, total_lifetime_seconds - grow_seconds)
	var fade_delay: float = grow_seconds * 0.70
	var fade_seconds: float = max(0.05, total_lifetime_seconds - fade_delay)

	var movement_tween: Tween = create_tween()
	movement_tween.bind_node(self)
	movement_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	movement_tween.tween_property(
		self,
		"position",
		destination,
		total_lifetime_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var scale_tween: Tween = create_tween()
	scale_tween.bind_node(self)
	scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scale_tween.tween_property(
		self,
		"scale",
		peak_scale,
		grow_seconds
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(
		self,
		"scale",
		end_scale,
		shrink_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var fade_tween: Tween = create_tween()
	fade_tween.bind_node(self)
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(
		self,
		"self_modulate:a",
		0.0,
		fade_seconds
	).set_delay(fade_delay)

	fade_tween.finished.connect(func() -> void:
		queue_free()
	)
