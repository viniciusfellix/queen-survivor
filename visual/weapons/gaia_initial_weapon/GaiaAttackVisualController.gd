## Controller visual temporário do ataque inicial da Gaia.
##
## Responsabilidades:
## - exibir placeholder ou visual Spine futuro do ataque;
## - rotacionar o visual conforme a direção de ataque;
## - aplicar lifetime;
## - aplicar fade out;
## - remover a instância automaticamente.
##
## Importante:
## Este script não calcula dano.
## A área ofensiva real é processada por DirectionalAttackHitbox.
extends Node2D
class_name GaiaAttackVisualController

## Modos visuais possíveis para o ataque.
enum VisualMode {
	PLACEHOLDER,
	SPINE
}

## Modo visual atual.
@export var visual_mode: VisualMode = VisualMode.PLACEHOLDER

@export_group("Node Paths")

## Root do visual placeholder.
@export var placeholder_root_path: NodePath

## Sprite do visual placeholder.
@export var placeholder_sprite_path: NodePath

## Root reservado para visual Spine futuro.
@export var spine_root_path: NodePath

@export_group("Placeholder")

## Caminho padrão da textura placeholder.
@export var default_placeholder_texture_path: String = "res://assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png"

## Textura placeholder opcional.
@export var placeholder_texture: Texture2D

@export_group("Direction")

## Offset de rotação adicional em graus.
@export var angle_offset_degrees: float = 0.0

@export_group("Lifetime")

## Tempo de vida do visual.
@export var lifetime_seconds: float = 0.22

## Define se o visual desaparece por alpha.
@export var fade_out: bool = true

## Define se o node deve ser removido ao fim do lifetime.
@export var auto_queue_free: bool = true

## Nodes visuais resolvidos.
@onready var placeholder_root: Node2D = get_node_or_null(placeholder_root_path) as Node2D
@onready var placeholder_sprite: Sprite2D = get_node_or_null(placeholder_sprite_path) as Sprite2D
@onready var spine_root: Node2D = get_node_or_null(spine_root_path) as Node2D

## Tempo decorrido desde que o visual nasceu.
var elapsed_seconds: float = 0.0

## Direção atual do ataque.
var attack_direction: Vector2 = Vector2.RIGHT

## Inicializa nodes, textura e rotação.
func _ready() -> void:
	_resolve_nodes_if_needed()
	_setup_placeholder_texture()
	_apply_visual_mode()
	_apply_direction_rotation()

## Atualiza fade e remove visual ao fim do lifetime.
func _process(delta: float) -> void:
	elapsed_seconds += delta

	if fade_out and lifetime_seconds > 0.0:
		var remaining_ratio: float = clamp(1.0 - (elapsed_seconds / lifetime_seconds), 0.0, 1.0)
		modulate.a = remaining_ratio

	if auto_queue_free and lifetime_seconds > 0.0 and elapsed_seconds >= lifetime_seconds:
		queue_free()

## Configura direção, lifetime e escala do visual.
##
## Chamado pelo controller da arma ao instanciar o ataque.
func setup(
	direction: Vector2,
	p_lifetime_seconds: float = -1.0,
	p_visual_scale: Vector2 = Vector2.ONE
) -> void:
	if direction.length() > 0.001:
		attack_direction = direction.normalized()
	else:
		attack_direction = Vector2.RIGHT

	if p_lifetime_seconds > 0.0:
		lifetime_seconds = p_lifetime_seconds

	scale = p_visual_scale
	elapsed_seconds = 0.0
	modulate.a = 1.0

	_apply_direction_rotation()

## Altera modo visual em runtime.
func set_visual_mode(new_mode: VisualMode) -> void:
	visual_mode = new_mode
	_apply_visual_mode()

## Resolve nodes por nomes padrão caso paths não estejam configurados.
func _resolve_nodes_if_needed() -> void:
	if placeholder_root == null:
		placeholder_root = get_node_or_null("PlaceholderRoot") as Node2D

	if placeholder_sprite == null:
		placeholder_sprite = get_node_or_null("PlaceholderRoot/Sprite2D") as Sprite2D

	if spine_root == null:
		spine_root = get_node_or_null("SpineRoot") as Node2D

## Carrega/aplica textura placeholder.
func _setup_placeholder_texture() -> void:
	if placeholder_sprite == null:
		return

	if placeholder_texture == null and ResourceLoader.exists(default_placeholder_texture_path):
		placeholder_texture = load(default_placeholder_texture_path) as Texture2D

	if placeholder_texture != null:
		placeholder_sprite.texture = placeholder_texture

## Exibe placeholder ou Spine conforme modo visual.
func _apply_visual_mode() -> void:
	if placeholder_root != null:
		placeholder_root.visible = visual_mode == VisualMode.PLACEHOLDER

	if spine_root != null:
		spine_root.visible = visual_mode == VisualMode.SPINE

## Rotaciona o visual para acompanhar a direção do ataque.
func _apply_direction_rotation() -> void:
	rotation = attack_direction.angle() + deg_to_rad(angle_offset_degrees)
