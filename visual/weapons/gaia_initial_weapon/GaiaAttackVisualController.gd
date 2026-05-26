## Controller visual do ataque inicial da Gaia.
##
## Responsabilidades:
## - representar visualmente um disparo direcional temporário;
## - alternar entre placeholder e futuro visual Spine;
## - rotacionar a arte conforme a direção do ataque;
## - aplicar fade e remover a instância ao finalizar sua duração.
##
## Este script não cria hitbox e não aplica dano.
## A lógica ofensiva pertence ao controller da arma e à hitbox.
extends Node2D
class_name GaiaAttackVisualController

## Modos visuais suportados pelo ataque.
##
## `PLACEHOLDER` utiliza imagem temporária.
## `SPINE` deixa preparada a substituição por animação real futura.
enum VisualMode {
	PLACEHOLDER,
	SPINE
}

## Modo visual atualmente utilizado pela instância do ataque.
@export var visual_mode: VisualMode = VisualMode.PLACEHOLDER

@export_group("Node Paths")

## Caminho opcional para o root do visual placeholder.
@export var placeholder_root_path: NodePath

## Caminho opcional para o Sprite2D do placeholder.
@export var placeholder_sprite_path: NodePath

## Caminho opcional para o root reservado ao visual Spine.
@export var spine_root_path: NodePath

@export_group("Placeholder")

## Caminho padrão da imagem provisória do ataque.
@export var default_placeholder_texture_path: String = "res://assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png"

## Textura opcional configurada diretamente pelo Inspector.
@export var placeholder_texture: Texture2D

@export_group("Direction")

## Correção angular aplicada caso a arte original não aponte para a direita.
##
## Exemplos:
## - `0`: textura já aponta para a direita;
## - `90`: textura original aponta para cima;
## - `-90`: textura original aponta para baixo.
@export var angle_offset_degrees: float = 0.0

@export_group("Lifetime")

## Duração visual máxima da instância do ataque.
@export var lifetime_seconds: float = 0.22

## Define se o ataque desaparece gradualmente ao longo de sua duração.
@export var fade_out: bool = true

## Define se a instância deve se remover automaticamente ao terminar.
@export var auto_queue_free: bool = true

## Nodes visuais resolvidos por path configurado ou fallback estrutural.
@onready var placeholder_root: Node2D = get_node_or_null(placeholder_root_path) as Node2D
@onready var placeholder_sprite: Sprite2D = get_node_or_null(placeholder_sprite_path) as Sprite2D
@onready var spine_root: Node2D = get_node_or_null(spine_root_path) as Node2D

## Tempo já transcorrido desde a criação ou reconfiguração do visual.
var elapsed_seconds: float = 0.0

## Direção normalizada aplicada à rotação do ataque.
var attack_direction: Vector2 = Vector2.RIGHT

## Resolve nodes, aplica textura, modo visual e rotação inicial.
func _ready() -> void:
	_resolve_nodes_if_needed()
	_setup_placeholder_texture()
	_apply_visual_mode()
	_apply_direction_rotation()

## Atualiza fade e destruição automática do visual.
func _process(delta: float) -> void:
	elapsed_seconds += delta

	if fade_out and lifetime_seconds > 0.0:
		var remaining_ratio: float = clamp(1.0 - (elapsed_seconds / lifetime_seconds), 0.0, 1.0)
		modulate.a = remaining_ratio

	if auto_queue_free and lifetime_seconds > 0.0 and elapsed_seconds >= lifetime_seconds:
		queue_free()

## Configura uma instância recém-criada de ataque visual.
##
## Recebe direção, duração opcional e escala definida pelo controller da arma.
## A direção inválida utiliza direita como fallback seguro.
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

## Altera o modo visual entre placeholder e Spine.
func set_visual_mode(new_mode: VisualMode) -> void:
	visual_mode = new_mode
	_apply_visual_mode()

## Resolve nodes visuais usando a estrutura padrão da cena
## quando nenhum caminho foi configurado no Inspector.
func _resolve_nodes_if_needed() -> void:
	if placeholder_root == null:
		placeholder_root = get_node_or_null("PlaceholderRoot") as Node2D

	if placeholder_sprite == null:
		placeholder_sprite = get_node_or_null("PlaceholderRoot/Sprite2D") as Sprite2D

	if spine_root == null:
		spine_root = get_node_or_null("SpineRoot") as Node2D

## Aplica ao Sprite2D a textura configurada ou a imagem placeholder padrão.
func _setup_placeholder_texture() -> void:
	if placeholder_sprite == null:
		return

	if placeholder_texture == null and ResourceLoader.exists(default_placeholder_texture_path):
		placeholder_texture = load(default_placeholder_texture_path) as Texture2D

	if placeholder_texture != null:
		placeholder_sprite.texture = placeholder_texture

## Mostra somente o root correspondente ao modo visual selecionado.
func _apply_visual_mode() -> void:
	if placeholder_root != null:
		placeholder_root.visible = visual_mode == VisualMode.PLACEHOLDER

	if spine_root != null:
		spine_root.visible = visual_mode == VisualMode.SPINE

## Rotaciona o visual na direção do disparo, considerando correção da arte.
func _apply_direction_rotation() -> void:
	rotation = attack_direction.angle() + deg_to_rad(angle_offset_degrees)
