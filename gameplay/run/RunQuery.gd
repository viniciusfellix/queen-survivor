extends RefCounted
class_name RunQuery

static func get_run_controller(scene_tree: SceneTree) -> Node:
	if scene_tree == null:
		return null

	var nodes: Array[Node] = scene_tree.get_nodes_in_group("run_controller")

	if nodes.is_empty():
		return null

	return nodes[0]

static func get_run_state(scene_tree: SceneTree) -> RunState:
	var run_controller: Node = get_run_controller(scene_tree)

	if run_controller == null:
		return null

	if not run_controller.has_method("get_run_state"):
		return null

	var run_state_variant: Variant = run_controller.call("get_run_state")

	if run_state_variant is RunState:
		return run_state_variant as RunState

	return null

static func is_run_ending(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_ending

static func is_run_finished(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_finished or run_state.is_victory or run_state.is_defeat

static func is_run_paused(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	if scene_tree.paused:
		return true

	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_paused

static func is_gameplay_blocked(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	if is_run_ending(scene_tree):
		return true

	if is_run_finished(scene_tree):
		return true

	if is_run_paused(scene_tree):
		return true

	return false
