## Controller visual base para entidades animadas com Spine.
##
## Responsabilidades:
## - localizar um adapter Spine descendente;
## - solicitar animações somente quando houver mudança real;
## - registrar mudanças visuais relevantes;
## - oferecer flip horizontal reutilizável;
## - expor helpers para animações em tracks superiores.
##
## Controllers específicos, como Gaia e Goblin, definem:
## - nomes de animações;
## - tradução de estado gameplay para animação;
## - comportamentos visuais próprios.
extends Node2D
class_name SpineVisualControllerBase

@export_group("Spine")

## Caminho opcional para o adapter Spine associado a este visual.
##
## Quando não configurado, o controller procura um descendente
## que exponha o método `play_animation`.
@export var spine_adapter_path: NodePath

@export_group("Diagnostics")

## Define se mudanças efetivas de estado/animação geram log técnico.
@export var log_visual_state_changes: bool = true

## Referência ao adapter Spine resolvido ao iniciar o controller.
@onready var spine_adapter: Node = _resolve_spine_adapter()

## Nome da última animação visual base aplicada com sucesso.
var current_animation_name: String = ""

## Nome lógico do estado visual atualmente aplicado.
var current_visual_state: String = ""

## Valida o adapter e inicia a animação padrão definida pela subclasse.
func _ready() -> void:
	if spine_adapter == null:
		push_warning("[%s] Spine adapter não encontrado." % _get_visual_log_name())
		return

	_play_initial_animation()

## Hook virtual para animação inicial.
##
## Cada controller específico deve sobrescrever este método,
## normalmente iniciando em estado idle.
func _play_initial_animation() -> void:
	pass

## Retorna o nome utilizado para logs e warnings deste visual.
func _get_visual_log_name() -> String:
	return name

## Toca uma animação base apenas quando ela difere da animação atual.
##
## Esta função controla a track principal, normalmente track 0.
## Overlays temporários, como blink, devem usar `_play_animation_on_track`.
func _play_animation_if_changed(
	animation_name: String,
	loop: bool,
	visual_state: String = ""
) -> bool:
	if animation_name.strip_edges() == "":
		return false

	if current_animation_name == animation_name:
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
		loop
	)

	var played_successfully: bool = bool(play_result_variant)

	if not played_successfully:
		return false

	current_animation_name = animation_name

	if visual_state.strip_edges() != "":
		current_visual_state = visual_state

	if log_visual_state_changes:
		DeveloperAuditLogger.log_animation(
			"Visual aplicado: state=%s animation=%s loop=%s" % [
				current_visual_state,
				current_animation_name,
				str(loop)
			],
			_get_visual_log_name(),
			{
				"visual_state": current_visual_state,
				"animation_name": current_animation_name,
				"loop": loop
			}
		)

	return true

## Toca uma animação em uma track específica sem necessariamente alterar
## a animação base registrada pelo controller.
##
## Usado para overlays temporários, como blink de olhos sobre idle/run.
func _play_animation_on_track(
	animation_name: String,
	loop: bool,
	track_index: int,
	updates_base_animation: bool = false
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
		updates_base_animation
	)

	return bool(play_result_variant)

## Limpa uma track específica quando o adapter/runtime Spine oferecer suporte.
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

## Espelha horizontalmente o visual conforme a direção recebida.
##
## Utiliza somente o eixo X e ignora direções neutras,
## preservando a última orientação visual válida.
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

## Resolve o adapter Spine por caminho configurado ou busca recursiva.
func _resolve_spine_adapter() -> Node:
	if spine_adapter_path != NodePath():
		var configured_adapter: Node = get_node_or_null(spine_adapter_path)

		if configured_adapter != null:
			return configured_adapter

	return _find_node_with_method(self, "play_animation")

## Procura recursivamente um node descendente que implemente um método.
##
## O próprio controller é ignorado para evitar resolver a si mesmo
## em possíveis subclasses que implementem métodos semelhantes.
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
