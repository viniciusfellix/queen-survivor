## Utilitário estático para consultar o estado global da run atual.
##
## Centraliza buscas pelo `RunController` e verificações de bloqueio
## utilizadas por armas, inimigos e drops sem criar dependência direta
## entre esses sistemas e a cena principal.
extends RefCounted
class_name RunQuery

## Localiza o primeiro node registrado no grupo `run_controller`.
##
## Retorna `null` quando não existe SceneTree válido ou controlador ativo.
static func get_run_controller(scene_tree: SceneTree) -> Node:
	if scene_tree == null:
		return null

	var nodes: Array[Node] = scene_tree.get_nodes_in_group("run_controller")

	if nodes.is_empty():
		return null

	return nodes[0]

## Obtém o `RunState` atual por meio do controlador registrado na cena.
##
## O acesso ocorre por método para evitar depender da implementação interna
## concreta do controller.
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

## Informa se a run já bloqueou gameplay para aguardar encerramento visual.
static func is_run_ending(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_ending

## Informa se a run já possui resultado definitivo.
static func is_run_finished(scene_tree: SceneTree) -> bool:
	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_finished or run_state.is_victory or run_state.is_defeat

## Informa se a run ou a árvore do Godot está pausada.
##
## A árvore é pausada durante level-up e após o encerramento final,
## enquanto `RunState.is_paused` mantém o estado lógico da run.
static func is_run_paused(scene_tree: SceneTree) -> bool:
	if scene_tree == null:
		return false

	if scene_tree.paused:
		return true

	var run_state: RunState = get_run_state(scene_tree)

	if run_state == null:
		return false

	return run_state.is_paused

## Informa se sistemas de gameplay devem parar de executar ações.
##
## Retorna `true` durante:
## - encerramento intermediário;
## - resultado final;
## - pausas, incluindo painel de level-up.
##
## Atenção: sistemas que precisam reagir ao evento que causou o level-up,
## como a criação do drop do inimigo derrotado, podem exigir regra específica
## em vez de utilizar este bloqueio geral.
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
