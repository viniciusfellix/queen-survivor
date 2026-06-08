## Indicador visual de mira/alcance da arma inicial da Gaia.
##
## Responsabilidades:
## - exibir um marcador visual do limite frontal do ataque;
## - acompanhar aim_direction sem alterar hitbox real;
## - permitir configuracao simples de textura, raio e escala;
## - permanecer totalmente separado do sistema de dano.
extends Node2D
class_name GaiaAimIndicator

@export_group("Indicator")
@export var indicator_enabled: bool = true
@export var sprite_path: NodePath
@export var default_texture_path: String = "res://assets/placeholders/weapons/gaia_initial_weapon/gaia_directional_attack.png"
@export var indicator_texture: Texture2D
@export var visual_radius_pixels: float = 256.0
@export var indicator_scale: Vector2 = Vector2.ONE
@export var position_offset: Vector2 = Vector2.ZERO
@export var angle_offset_degrees: float = 0.0

@onready var indicator_sprite: Sprite2D = get_node_or_null(sprite_path) as Sprite2D

var current_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_resolve_nodes_if_needed()
	_setup_texture_if_needed()
	_apply_visibility()
	_apply_transform()

func configure_indicator(
	radius_pixels: float,
	is_enabled: bool = true
) -> void:
	visual_radius_pixels = max(0.0, radius_pixels)
	indicator_enabled = is_enabled
	_apply_visibility()
	_apply_transform()

func set_visual_radius_pixels(radius_pixels: float) -> void:
	visual_radius_pixels = max(0.0, radius_pixels)
	_apply_transform()

func set_indicator_enabled(is_enabled: bool) -> void:
	indicator_enabled = is_enabled
	_apply_visibility()

func apply_aim_direction(direction: Vector2) -> void:
	if direction.length() > 0.001:
		current_direction = direction.normalized()
	else:
		current_direction = Vector2.RIGHT

	_apply_transform()

func _resolve_nodes_if_needed() -> void:
	if indicator_sprite == null:
		indicator_sprite = get_node_or_null("Sprite2D") as Sprite2D

func _setup_texture_if_needed() -> void:
	if indicator_sprite == null:
		return

	if indicator_texture == null and ResourceLoader.exists(default_texture_path):
		indicator_texture = load(default_texture_path) as Texture2D

	if indicator_texture != null:
		indicator_sprite.texture = indicator_texture

	indicator_sprite.scale = indicator_scale

func _apply_visibility() -> void:
	visible = indicator_enabled

func _apply_transform() -> void:
	var safe_direction: Vector2 = current_direction

	if safe_direction.length() <= 0.001:
		safe_direction = Vector2.RIGHT

	position = safe_direction.normalized() * visual_radius_pixels + position_offset
	rotation = safe_direction.angle() + deg_to_rad(angle_offset_degrees)

	if indicator_sprite != null:
		indicator_sprite.scale = indicator_scale
