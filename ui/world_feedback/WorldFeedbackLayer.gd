## Camada responsável por converter eventos do mundo em feedback visual na tela.
##
## No Módulo 1, sua função principal é exibir o dano recebido pela Gaia
## como texto flutuante acima da personagem.
##
## Esta camada:
## - escuta `player_damaged`;
## - localiza o player no mundo;
## - converte posição mundial em posição de tela;
## - instancia `FloatingCombatText`;
## - não calcula dano e não altera HP.
extends CanvasLayer

@export_group("Scene")

## Cena instanciada para cada texto flutuante exibido.
@export var floating_combat_text_scene: PackedScene

@export_group("Player Damage")

## Grupo utilizado para localizar a Queen na árvore atual.
@export var player_group_name: String = "player"

## Deslocamento mundial aplicado à posição da Queen.
##
## Permite colocar o número acima da cabeça da arte Spine
## sem acoplar esta camada ao tamanho visual específico da personagem.
@export var player_damage_world_offset: Vector2 = Vector2(0.0, -60.0)

## Cor utilizada para textos de dano recebido pelo player.
@export var damage_color: Color = Color(1.0, 0.04, 0.04, 1.0)

@export_group("Debug")

## Ativa logs detalhados sempre que um texto flutuante é criado.
@export var debug_feedback: bool = false

## Exibe um texto de teste ao inicializar a cena.
##
## Deve permanecer desativado durante gameplay normal.
@export var show_test_text_on_ready: bool = false

## Container fullscreen que recebe instâncias de texto flutuante.
@onready var feedback_root: Control = $FeedbackRoot

## Inicializa a camada, configura seu root e conecta o evento de dano.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 18

	_configure_feedback_root()

	if not GameEvents.player_damaged.is_connected(_on_player_damaged):
		GameEvents.player_damaged.connect(_on_player_damaged)

	DeveloperAuditLogger.log_ui(
		"Feedback flutuante inicializado. root=%s scene=%s" % [
			str(feedback_root != null),
			str(floating_combat_text_scene != null)
		],
		"WorldFeedbackLayer",
		{
			"has_feedback_root": feedback_root != null,
			"has_floating_text_scene": floating_combat_text_scene != null
		}
	)

	if show_test_text_on_ready:
		call_deferred("_spawn_debug_test_text")

## Configura o container de textos para ocupar toda a viewport.
##
## Não define tamanho manualmente, pois o preset Full Rect
## já permite ao Godot recalcular corretamente o Control.
func _configure_feedback_root() -> void:
	if feedback_root == null:
		return

	feedback_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_root.clip_contents = false
	feedback_root.process_mode = Node.PROCESS_MODE_ALWAYS

## Reage ao dano recebido pela Queen e cria o texto correspondente.
##
## Apenas danos efetivamente aplicados, maiores que zero,
## resultam em feedback visual.
func _on_player_damaged(
	_raw_damage: int,
	final_damage: int,
	_current_hp: int,
	_max_hp: int,
	_source_id: String
) -> void:
	if final_damage <= 0:
		return

	var player_node: Node2D = _get_player()

	if player_node == null:
		push_warning("[WorldFeedbackLayer] Floating damage cancelado: player não encontrado.")
		return

	var world_position: Vector2 = player_node.global_position + player_damage_world_offset
	var screen_position: Vector2 = _world_to_screen_position(world_position)

	spawn_floating_text("-%s" % str(final_damage), screen_position, damage_color)

## Instancia e posiciona um texto flutuante na camada de tela.
##
## O texto recebe sua animação internamente pelo método `setup()`
## da cena `FloatingCombatText`.
func spawn_floating_text(display_text: String, screen_position: Vector2, color: Color) -> void:
	if feedback_root == null:
		push_warning("[WorldFeedbackLayer] Floating damage cancelado: FeedbackRoot ausente.")
		return

	if floating_combat_text_scene == null:
		push_warning("[WorldFeedbackLayer] FloatingCombatText scene não configurada.")
		return

	var instance: Node = floating_combat_text_scene.instantiate()

	if not instance is Control:
		push_warning("[WorldFeedbackLayer] FloatingCombatText precisa ter root do tipo Control ou Label.")
		instance.queue_free()
		return

	var text_control: Control = instance as Control

	feedback_root.add_child(text_control)

	# Centraliza o texto sobre a posição de tela calculada.
	text_control.position = screen_position - (text_control.size * 0.5)
	text_control.visible = true

	if text_control.has_method("setup"):
		text_control.call("setup", display_text, color)

	if debug_feedback:
		DeveloperAuditLogger.log_ui(
			"Floating damage exibido: text=%s screen=%s final_pos=%s" % [
				display_text,
				str(screen_position),
				str(text_control.position)
			],
			"WorldFeedbackLayer",
			{
				"text": display_text,
				"screen_position": screen_position,
				"final_position": text_control.position
			}
		)

## Cria um texto flutuante artificial no centro da viewport.
##
## Utilizado somente para validar renderização e animação
## sem depender de um dano real durante testes.
func _spawn_debug_test_text() -> void:
	var center_position: Vector2 = get_viewport().get_visible_rect().size * 0.5

	spawn_floating_text(
		"TESTE -6",
		center_position,
		damage_color
	)

## Converte uma posição do mundo 2D para coordenadas da viewport.
##
## Considera transformações atuais da câmera.
func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform * world_position

## Retorna a primeira entidade `Node2D` registrada no grupo do player.
func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
