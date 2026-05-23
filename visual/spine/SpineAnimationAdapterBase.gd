extends Node
class_name SpineAnimationAdapterBase

@export_group("Spine")
@export var spine_sprite_path: NodePath

@export_group("Diagnostics")
@export var log_ready_status: bool = true
@export var log_animation_changes: bool = false

@onready var spine_sprite: Node = _resolve_spine_sprite()

var current_animation_name: String = ""
var is_spine_ready: bool = false

func _ready() -> void:
	is_spine_ready = spine_sprite != null

	if not log_ready_status:
		return

	if is_spine_ready:
		GameEvents.emit_debug("[%s] SpineSprite encontrado: %s" % [
			_get_adapter_log_name(),
			spine_sprite.name
		])
	else:
		push_warning("[%s] SpineSprite não configurado ou não encontrado." % _get_adapter_log_name())

func play_animation(animation_name: String, loop: bool = true) -> bool:
	if animation_name.strip_edges() == "":
		return false

	if not is_spine_ready:
		push_warning("[%s] Não foi possível tocar animação; SpineSprite ausente: %s" % [
			_get_adapter_log_name(),
			animation_name
		])
		return false

	if current_animation_name == animation_name:
		return true

	var played: bool = _try_play_with_animation_state(animation_name, loop)

	if not played:
		push_warning("[%s] Falha ao tocar animação pela API Spine: %s" % [
			_get_adapter_log_name(),
			animation_name
		])
		return false

	current_animation_name = animation_name

	if _should_publish_animation_changed():
		GameEvents.spine_animation_changed.emit(animation_name)

	if log_animation_changes:
		GameEvents.emit_debug("[%s] Tocando animação: %s | loop=%s" % [
			_get_adapter_log_name(),
			animation_name,
			str(loop)
		])

	return true

func get_current_animation_name() -> String:
	return current_animation_name

func is_ready_for_animation() -> bool:
	return is_spine_ready

func _should_publish_animation_changed() -> bool:
	return false

func _get_adapter_log_name() -> String:
	return name

func _resolve_spine_sprite() -> Node:
	if spine_sprite_path != NodePath():
		var configured_node: Node = get_node_or_null(spine_sprite_path)

		if configured_node != null:
			return configured_node

	var sibling: Node = get_node_or_null("../SpineSprite")

	if sibling != null and sibling.get_class() == "SpineSprite":
		return sibling

	var parent_node: Node = get_parent()

	if parent_node == null:
		return null

	return _find_first_spine_sprite(parent_node)

func _find_first_spine_sprite(root: Node) -> Node:
	if root == null:
		return null

	if root.get_class() == "SpineSprite":
		return root

	for child: Node in root.get_children():
		var found: Node = _find_first_spine_sprite(child)

		if found != null:
			return found

	return null

func _try_play_with_animation_state(animation_name: String, loop: bool) -> bool:
	if spine_sprite == null:
		return false

	if not spine_sprite.has_method("get_animation_state"):
		return false

	var animation_state_variant: Variant = spine_sprite.call("get_animation_state")

	if animation_state_variant == null:
		return false

	if not animation_state_variant is Object:
		return false

	var animation_state: Object = animation_state_variant as Object

	if not animation_state.has_method("set_animation"):
		return false

	animation_state.call("set_animation", animation_name, loop, 0)

	return true
