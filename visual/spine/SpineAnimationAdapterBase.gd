## Adapter base responsável por conversar diretamente com o plugin Spine.
##
## Responsabilidades:
## - localizar o `SpineSprite` associado ao visual;
## - executar animações pela API exposta pelo plugin;
## - evitar reiniciar uma animação base que já está ativa;
## - permitir animações em tracks superiores, como blink sobre idle/run;
## - limpar tracks temporárias quando o efeito visual termina;
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

## Nome da animação base atualmente enviada ao SpineSprite.
##
## Este valor representa a track principal, normalmente track 0.
var current_animation_name: String = ""

## Animação ativa conhecida por track.
##
## Usado para impedir reinício desnecessário em tracks temporárias,
## sem confundir a animação base com overlays como blink.
var current_animation_by_track: Dictionary = {}

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

## Solicita a reprodução de uma animação base no SpineSprite.
##
## Por padrão, esta função toca na track 0 e atualiza `current_animation_name`.
## Para overlays temporários, como blink de olhos, use `play_animation_on_track`.
func play_animation(animation_name: String, loop: bool = true) -> bool:
	return play_animation_on_track(animation_name, loop, 0, true)

## Solicita a reprodução de uma animação em uma track específica.
##
## Uso esperado:
## - track 0: animações base, como idle/run/dash/death;
## - track 1+: overlays temporários, como blink.
##
## Quando `updates_base_animation` for false, a animação não altera
## `current_animation_name`, evitando que um blink temporário substitua
## conceitualmente o estado visual base.
func play_animation_on_track(
	animation_name: String,
	loop: bool = true,
	track_index: int = 0,
	updates_base_animation: bool = false
) -> bool:
	if animation_name.strip_edges() == "":
		return false

	var safe_track_index: int = max(0, track_index)

	if not is_spine_ready:
		push_warning("[%s] Não foi possível tocar animação; SpineSprite ausente: %s" % [
			_get_adapter_log_name(),
			animation_name
		])
		return false

	var current_track_animation: String = str(
		current_animation_by_track.get(safe_track_index, "")
	)

	if current_track_animation == animation_name:
		return true

	var played_successfully: bool = _try_play_with_animation_state(
		animation_name,
		loop,
		safe_track_index
	)

	if not played_successfully:
		push_warning("[%s] Falha ao tocar animação pela API Spine: %s | track=%s" % [
			_get_adapter_log_name(),
			animation_name,
			str(safe_track_index)
		])
		return false

	current_animation_by_track[safe_track_index] = animation_name

	if updates_base_animation or safe_track_index == 0:
		current_animation_name = animation_name

		if _should_publish_animation_changed():
			GameEvents.spine_animation_changed.emit(animation_name)

	if log_animation_changes:
		DeveloperAuditLogger.log_animation(
			"Animação executada: %s | loop=%s | track=%s | updates_base=%s" % [
				animation_name,
				str(loop),
				str(safe_track_index),
				str(updates_base_animation)
			],
			_get_adapter_log_name(),
			{
				"animation_name": animation_name,
				"loop": loop,
				"track_index": safe_track_index,
				"updates_base_animation": updates_base_animation
			}
		)

	return true

## Limpa uma track temporária do Spine, quando a API do plugin permitir.
##
## Isso é importante para overlays como blink, pois evita que a última pose
## da track superior continue influenciando o esqueleto depois da animação.
func clear_animation_track(track_index: int) -> bool:
	var safe_track_index: int = max(0, track_index)

	current_animation_by_track.erase(safe_track_index)

	if safe_track_index == 0:
		current_animation_name = ""

	if not is_spine_ready:
		return false

	var cleared_successfully: bool = _try_clear_animation_track(safe_track_index)

	if log_animation_changes:
		DeveloperAuditLogger.log_animation(
			"Track limpa: track=%s success=%s" % [
				str(safe_track_index),
				str(cleared_successfully)
			],
			_get_adapter_log_name(),
			{
				"track_index": safe_track_index,
				"success": cleared_successfully
			}
		)

	return cleared_successfully

## Retorna o nome da animação base atualmente ativa neste adapter.
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
## A assinatura usada preserva o padrão já funcional no projeto:
## `set_animation(animation_name, loop, track_index)`.
func _try_play_with_animation_state(
	animation_name: String,
	loop: bool,
	track_index: int
) -> bool:
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

	animation_state.call("set_animation", animation_name, loop, track_index)

	return true

## Tenta limpar uma track pela API do plugin Spine.
##
## Alguns plugins expõem `clear_track(track)`.
## Caso não exista, tentamos `set_empty_animation(track, mix_duration)`.
## Se nenhuma API existir, retornamos false; nesse caso, a animação não-loop
## pode ainda encerrar sozinha, dependendo do runtime Spine.
func _try_clear_animation_track(track_index: int) -> bool:
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

	if animation_state.has_method("clear_track"):
		animation_state.call("clear_track", track_index)
		return true

	if animation_state.has_method("set_empty_animation"):
		animation_state.call("set_empty_animation", track_index, 0.05)
		return true

	return false
