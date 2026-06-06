## Utilitário estático para consultar o estado global da run.
##
## Responsabilidades:
## - localizar RunController pelo grupo `run_controller`;
## - acessar RunState com segurança;
## - responder se a run está encerrando ou finalizada.
##
## Observação:
## A pausa de gameplay (level-up, fim de run) é feita pela pausa nativa do Godot
## (`get_tree().paused` + `process_mode = ALWAYS` na UI), não mais por uma checagem
## "is_gameplay_blocked" lida a cada frame. Estas funções servem a callbacks de
## evento (ex.: não dropar moeda durante o encerramento), não a `_process`.
extends RefCounted
class_name RunQuery

## Localiza o RunController registrado no grupo run_controller.
static func get_run_controller(scene_tree: SceneTree) -> Node:
	if scene_tree == null:
		return null

	var nodes: Array[Node] = scene_tree.get_nodes_in_group("run_controller")

	if nodes.is_empty():
		return null

	return nodes[0]

## Obtém RunState a partir do RunController, se disponível.
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

## Indica se a run iniciou encerramento e deve bloquear gameplay.
static func is_run_ending(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_ending

## Indica se a run já terminou em vitória ou derrota.
static func is_run_finished(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_finished or run_state.is_victory or run_state.is_defeat
