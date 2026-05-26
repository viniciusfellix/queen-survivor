## Adapter base responsável por conversar diretamente com o plugin Spine.
##
## Responsabilidades:
## - localizar o `SpineSprite` associado ao visual;
## - executar animações pela API exposta pelo plugin;
## - evitar reiniciar uma animação que já está ativa;
## - disponibilizar hooks para adapters específicos publicarem events.
##
## Controllers visuais não devem acessar diretamente o plugin Spine;
## eles solicitam animações por meio deste adapter.
extends Node
class_name SpineAnimationAdapterBase

@export_group("Spine")

## Caminho opcional para o SpineSprite controlado por este adapter.
##
## Quando não configurado, o adapter procura:
## 1. um sibling chamado `SpineSprite`;
## 2. o primeiro SpineSprite encontrado dentro do node pai.
@export var spine_sprite_path: NodePath

@export_group("Diagnostics")

## Define se a localização bem-sucedida do SpineSprite gera log técnico.
@export var log_ready_status: bool = true

## Define se cada troca de animação gera log técnico.
@export var log_animation_changes: bool = false

## Referência ao SpineSprite resolvida na inicialização do node.
@onready var spine_sprite: Node = _resolve_spine_sprite()

## Nome da animação atualmente enviada ao SpineSprite.
var current_animation_name: String = ""

## Indica se o adapter localizou corretamente o SpineSprite necessário.
var is_spine_ready: bool = false

## Valida a disponibilidade do SpineSprite ao iniciar o adapter.
func _ready() -> void:
	is_spine_ready = spine_sprite != null

	if not is_spine_ready:
		push_warning("[%s] SpineSprite não configurado ou não encontrado." % _get_adapter_log_name())
		return

	if log_ready_status:
		DeveloperAuditLogger.log_animation(
			"SpineSprite encontrado: %s" % spine_sprite.name,
			_get_adapter_log_name(),
			{
				"spine_sprite_name": spine_sprite.name
			}
		)

## Solicita a reprodução de uma animação no SpineSprite.
##
## Retorna `true` quando:
## - a animação solicitada já estava ativa; ou
## - a execução pela API Spine foi concluída com sucesso.
##
## Retorna `false` quando o nome é inválido, o SpineSprite está ausente
## ou o plugin não expõe os métodos necessários.
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

	var played_successfully: bool = _try_play_with_animation_state(animation_name, loop)

	if not played_successfully:
		push_warning("[%s] Falha ao tocar animação pela API Spine: %s" % [
			_get_adapter_log_name(),
			animation_name
		])
		return false

	current_animation_name = animation_name

	if _should_publish_animation_changed():
		GameEvents.spine_animation_changed.emit(animation_name)

	if log_animation_changes:
		DeveloperAuditLogger.log_animation(
			"Animação executada: %s | loop=%s" % [
				animation_name,
				str(loop)
			],
			_get_adapter_log_name(),
			{
				"animation_name": animation_name,
				"loop": loop
			}
		)

	return true

## Retorna o nome da animação atualmente ativa neste adapter.
func get_current_animation_name() -> String:
	return current_animation_name

## Informa se o adapter possui um SpineSprite pronto para uso.
func is_ready_for_animation() -> bool:
	return is_spine_ready

## Hook sobrescrevível que define se trocas de animação serão publicadas.
##
## No protótipo atual, apenas a Gaia publica este signal,
## pois o DebugOverlay apresenta a animação atual do player.
func _should_publish_animation_changed() -> bool:
	return false

## Retorna o nome utilizado nos logs deste adapter.
##
## Adapters específicos sobrescrevem este método para produzir
## identificação estável no console.
func _get_adapter_log_name() -> String:
	return name

## Localiza o SpineSprite controlado por este adapter.
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

## Procura recursivamente o primeiro node SpineSprite dentro de uma árvore.
##
## Este helper elimina repetição de busca entre visuals de Queens e inimigos.
func _find_first_spine_sprite(root: Node) -> Node:
	if root == null:
		return null

	if root.get_class() == "SpineSprite":
		return root

	for child: Node in root.get_children():
		var found_node: Node = _find_first_spine_sprite(child)

		if found_node != null:
			return found_node

	return null

## Executa a chamada efetiva à API do plugin Spine.
##
## A verificação dinâmica mantém o projeto protegido caso o node
## configurado não possua a interface esperada pelo adapter.
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
