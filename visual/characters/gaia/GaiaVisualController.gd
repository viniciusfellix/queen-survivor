extends Node2D

@export var spine_adapter_path: NodePath

@export var idle_animation_name: String = "Idle1_Pose2"
@export var blink_idle_animation_name: String = "Blink_Idle_Pose2"
@export var run_animation_name: String = "Run1_Pose3"
@export var dash_animation_name: String = "Dash1_Pose3"
@export var death_animation_name: String = "Die_Pose1"
@export var ultimate_animation_name: String = "Ultimate1_Pose1"

@onready var spine_adapter: Node = _resolve_spine_adapter()

var current_animation_name: String = ""
var last_applied_gameplay_state: String = ""

func _ready() -> void:
	if spine_adapter == null:
		GameEvents.emit_debug("[GaiaVisualController] Spine adapter NÃO encontrado.")
	else:
		GameEvents.emit_debug("[GaiaVisualController] Spine adapter encontrado: %s" % spine_adapter.name)

	play_idle()

func apply_runtime_state(runtime_state: PlayerRuntimeState) -> void:
	if runtime_state == null:
		return

	_update_facing(runtime_state.facing_direction)

	var gameplay_state: String = runtime_state.current_gameplay_state
	runtime_state.current_visual_state = gameplay_state

	if gameplay_state != last_applied_gameplay_state:
		last_applied_gameplay_state = gameplay_state
		GameEvents.emit_debug("[GaiaVisualController] Estado visual aplicado: %s" % gameplay_state)

	match gameplay_state:
		GameplayStateTypes.IDLE:
			play_idle()
		GameplayStateTypes.MOVING:
			play_run()
		GameplayStateTypes.DASHING:
			play_dash()
		GameplayStateTypes.DEAD:
			play_death()
		_:
			play_idle()

func play_idle() -> void:
	_play_animation_if_changed(idle_animation_name, true)

func play_run() -> void:
	_play_animation_if_changed(run_animation_name, true)

func play_dash() -> void:
	_play_animation_if_changed(dash_animation_name, false)

func play_death() -> void:
	_play_animation_if_changed(death_animation_name, false)

func play_ultimate_test() -> void:
	_play_animation_if_changed(ultimate_animation_name, false)

func _play_animation_if_changed(animation_name: String, loop: bool) -> void:
	if animation_name.strip_edges() == "":
		return

	if current_animation_name == animation_name:
		return

	current_animation_name = animation_name

	if spine_adapter != null and spine_adapter.has_method("play_animation"):
		spine_adapter.call("play_animation", animation_name, loop)
	else:
		GameEvents.emit_debug("[GaiaVisualController] Não foi possível tocar animação. Adapter ausente: %s" % animation_name)

	GameEvents.spine_animation_changed.emit(animation_name)

func _update_facing(facing_direction: Vector2) -> void:
	if abs(facing_direction.x) <= 0.001:
		return

	if facing_direction.x < 0.0:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)

func _resolve_spine_adapter() -> Node:
	if spine_adapter_path != NodePath():
		var configured_adapter: Node = get_node_or_null(spine_adapter_path)

		if configured_adapter != null:
			return configured_adapter

	var direct_adapter: Node = get_node_or_null("GaiaSpineAdapter")

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
