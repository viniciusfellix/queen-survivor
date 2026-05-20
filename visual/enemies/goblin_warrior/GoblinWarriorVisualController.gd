extends Node2D

@export var spine_adapter_path: NodePath

@export var idle_animation_name: String = "Idle"
@export var run_animation_name: String = "Run"
@export var walk_animation_name: String = "Run"
@export var death_animation_name: String = "Die"

@export var use_walk_when_run_missing: bool = true
@export var flip_by_movement_direction: bool = true

@onready var spine_adapter: Node = _resolve_spine_adapter()

var current_visual_state: String = ""
var current_animation_name: String = ""

func _ready() -> void:
	if spine_adapter == null:
		GameEvents.emit_debug("[GoblinWarriorVisualController] Spine adapter NÃO encontrado.")
	else:
		GameEvents.emit_debug("[GoblinWarriorVisualController] Spine adapter encontrado: %s" % spine_adapter.name)

	play_idle()

func apply_enemy_runtime_state(is_moving: bool, movement_direction: Vector2, is_alive: bool = true) -> void:
	if not is_alive:
		play_death()
		return

	_update_facing(movement_direction)

	if is_moving:
		play_run()
	else:
		play_idle()

func play_idle() -> void:
	_play_animation_if_changed(idle_animation_name, true, "idle")

func play_run() -> void:
	var selected_animation: String = run_animation_name

	if selected_animation.strip_edges() == "" and use_walk_when_run_missing:
		selected_animation = walk_animation_name

	_play_animation_if_changed(selected_animation, true, "run")

func play_death() -> void:
	_play_animation_if_changed(death_animation_name, false, "death")

func _play_animation_if_changed(animation_name: String, loop: bool, visual_state: String) -> void:
	if animation_name.strip_edges() == "":
		return

	if current_animation_name == animation_name:
		return

	current_visual_state = visual_state
	current_animation_name = animation_name

	if spine_adapter != null and spine_adapter.has_method("play_animation"):
		spine_adapter.call("play_animation", animation_name, loop)
	else:
		GameEvents.emit_debug("[GoblinWarriorVisualController] Adapter ausente. Não foi possível tocar: %s" % animation_name)

func _update_facing(movement_direction: Vector2) -> void:
	if not flip_by_movement_direction:
		return

	if abs(movement_direction.x) <= 0.001:
		return

	if movement_direction.x < 0.0:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)

func _resolve_spine_adapter() -> Node:
	if spine_adapter_path != NodePath():
		var configured_adapter: Node = get_node_or_null(spine_adapter_path)

		if configured_adapter != null:
			return configured_adapter

	var direct_adapter: Node = get_node_or_null("GoblinWarriorSpineAdapter")

	if direct_adapter != null:
		return direct_adapter

	var found_adapter: Node = _find_node_with_method(self, "play_animation")

	if found_adapter != null and found_adapter != self:
		return found_adapter

	return null

func _find_node_with_method(root: Node, method_name: String) -> Node:
	if root == null:
		return null

	if root.has_method(method_name):
		return root

	for child: Node in root.get_children():
		var found: Node = _find_node_with_method(child, method_name)

		if found != null:
			return found

	return null
