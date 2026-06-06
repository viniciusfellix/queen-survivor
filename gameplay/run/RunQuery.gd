## Utilitário estático para consultar o estado global da run.
##
## Responsabilidades:
## - localizar RunController pelo grupo `run_controller`;
## - acessar RunState com segurança;
## - responder se a run está pausada, encerrando ou finalizada;
## - centralizar a pergunta "o gameplay está bloqueado?".
##
## Usado por hitboxes, inimigos, drops e sistemas runtime para evitar processamento
## indevido após vitória, derrota, pausa ou início do encerramento.
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

## Indica se a árvore ou o RunState estão pausados.
static func is_run_paused(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	if scene_tree.paused:
		return true

	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_paused

## Centraliza a regra de bloqueio de gameplay para sistemas runtime.
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
