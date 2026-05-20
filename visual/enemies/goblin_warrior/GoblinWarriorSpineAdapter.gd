extends Node

@export var spine_sprite_path: NodePath

@onready var spine_sprite: Node = _resolve_spine_sprite()

var current_animation_name: String = ""
var is_spine_ready: bool = false

func _ready() -> void:
	is_spine_ready = spine_sprite != null

	if is_spine_ready:
		GameEvents.emit_debug("[GoblinWarriorSpineAdapter] SpineSprite encontrado: %s" % spine_sprite.name)
	else:
		GameEvents.emit_debug("[GoblinWarriorSpineAdapter] SpineSprite não configurado ou não encontrado.")

func play_animation(animation_name: String, loop: bool = true) -> void:
	if not is_spine_ready:
		GameEvents.emit_debug("[GoblinWarriorSpineAdapter] Ignorando animação. SpineSprite ausente: %s" % animation_name)
		return

	if animation_name.strip_edges() == "":
		return

	if current_animation_name == animation_name:
		return

	current_animation_name = animation_name

	var played: bool = _try_play_with_animation_state(animation_name, loop)

	if played:
		GameEvents.emit_debug("[GoblinWarriorSpineAdapter] Tocando animação: %s | loop=%s" % [animation_name, str(loop)])
	else:
		GameEvents.emit_debug("[GoblinWarriorSpineAdapter] Não consegui tocar por código ainda: %s" % animation_name)

func get_current_animation_name() -> String:
	return current_animation_name

func _resolve_spine_sprite() -> Node:
	if spine_sprite_path != NodePath():
		var configured_node: Node = get_node_or_null(spine_sprite_path)

		if configured_node != null:
			return configured_node

	var sibling: Node = get_node_or_null("../SpineSprite")

	if sibling != null:
		return sibling

	var parent_node: Node = get_parent()

	if parent_node != null:
		var found: Node = _find_first_spine_sprite(parent_node)

		if found != null:
			return found

	return null

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

	var animation_state: Variant = spine_sprite.call("get_animation_state")

	if animation_state == null:
		return false

	if not animation_state is Object:
		return false

	var animation_state_object: Object = animation_state as Object

	if animation_state_object.has_method("set_animation"):
		animation_state_object.call("set_animation", animation_name, loop, 0)
		return true

	return false
