## Controller visual base para personagens/entidades com Spine.
##
## Responsabilidades:
## - localizar adapter Spine;
## - pedir execução de animações;
## - evitar repetir animação igual;
## - aplicar flip horizontal;
## - oferecer helpers para tracks superiores;
## - centralizar logs visuais.
##
## Importante:
## Este controller não decide gameplay.
## Ele apenas traduz estado de gameplay em animação.
extends Node2D
class_name SpineVisualControllerBase

@export_group("Spine")

## Caminho opcional para o adapter Spine.
@export var spine_adapter_path: NodePath

@export_group("Diagnostics")

## Loga mudanças visuais quando ativo.
@export var log_visual_state_changes: bool = true

## Referência ao adapter visual.
@onready var spine_adapter: Node = _resolve_spine_adapter()

## Nome da animação base atual.
var current_animation_name: String = ""

## Estado visual atual.
var current_visual_state: String = ""

## Time scale da animação base atual.
var current_animation_time_scale: float = 1.0

## Inicializa e toca animação inicial.
func _ready() -> void:
	if spine_adapter == null:
		push_warning("[%s] Spine adapter não encontrado." % _get_visual_log_name())
		return

	_play_initial_animation()

## Hook para subclasses definirem animação inicial.
func _play_initial_animation() -> void:
	pass

## Nome usado em logs.
func _get_visual_log_name() -> String:
	return name

## Toca animação base somente se mudou.
func _play_animation_if_changed(
	animation_name: String,
	loop: bool,
	visual_state: String = "",
	time_scale: float = 1.0
) -> bool:
	if animation_name.strip_edges() == "":
		return false

	if (
		current_animation_name == animation_name
		and current_visual_state == visual_state
		and is_equal_approx(current_animation_time_scale, time_scale)
	):
		return true

	if spine_adapter == null:
		push_warning("[%s] Adapter ausente. Não foi possível tocar animação: %s" % [
			_get_visual_log_name(),
			animation_name
		])
		return false

	if not spine_adapter.has_method("play_animation"):
		push_warning("[%s] Adapter não implementa play_animation: %s" % [
			_get_visual_log_name(),
			animation_name
		])
		return false

	var play_result_variant: Variant = spine_adapter.call(
		"play_animation",
		animation_name,
		loop,
		time_scale
	)

	var played_successfully: bool = bool(play_result_variant)

	if not played_successfully:
		return false

	current_animation_time_scale = max(0.01, time_scale)
	current_animation_name = animation_name

	if visual_state.strip_edges() != "":
		current_visual_state = visual_state

	if log_visual_state_changes:
		DeveloperAuditLogger.log_animation(
			"Visual aplicado: state=%s animation=%s loop=%s time_scale=%s" % [
				current_visual_state,
				current_animation_name,
				str(loop),
				str(time_scale)
			],
			_get_visual_log_name(),
			{
				"visual_state": current_visual_state,
				"animation_name": current_animation_name,
				"loop": loop,
				"time_scale": time_scale
			}
		)

	return true

## Toca animação em track específica.
##
## Usado para overlays, como blink em track superior.
func _play_animation_on_track(
	animation_name: String,
	loop: bool,
	track_index: int,
	updates_base_animation: bool = false,
	time_scale: float = 1.0
) -> bool:
	if animation_name.strip_edges() == "":
		return false

	if spine_adapter == null:
		push_warning("[%s] Adapter ausente. Não foi possível tocar animação em track: %s" % [
			_get_visual_log_name(),
			animation_name
		])
		return false

	if not spine_adapter.has_method("play_animation_on_track"):
		push_warning("[%s] Adapter não implementa play_animation_on_track: %s" % [
			_get_visual_log_name(),
			animation_name
		])
		return false

	var play_result_variant: Variant = spine_adapter.call(
		"play_animation_on_track",
		animation_name,
		loop,
		track_index,
		updates_base_animation,
		time_scale
	)

	return bool(play_result_variant)

## Limpa uma track específica no adapter.
func _clear_animation_track(track_index: int) -> bool:
	if spine_adapter == null:
		return false

	if not spine_adapter.has_method("clear_animation_track"):
		return false

	var result_variant: Variant = spine_adapter.call(
		"clear_animation_track",
		track_index
	)

	return bool(result_variant)

## Aplica flip horizontal pelo sinal do eixo X.
func _apply_horizontal_facing(
	facing_direction: Vector2,
	should_flip: bool = true
) -> void:
	if not should_flip:
		return

	if abs(facing_direction.x) <= 0.001:
		return

	if facing_direction.x < 0.0:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)

## Resolve adapter por path ou busca recursiva.
func _resolve_spine_adapter() -> Node:
	if spine_adapter_path != NodePath():
		var configured_adapter: Node = get_node_or_null(spine_adapter_path)

		if configured_adapter != null:
			return configured_adapter

	return _find_node_with_method(self, "play_animation")

## Busca recursivamente um node que implemente determinado método.
func _find_node_with_method(root: Node, method_name: String) -> Node:
	if root == null:
		return null

	if root != self and root.has_method(method_name):
		return root

	for child: Node in root.get_children():
		var found_node: Node = _find_node_with_method(child, method_name)

		if found_node != null:
			return found_node

	return null
