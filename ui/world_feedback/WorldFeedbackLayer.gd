## Camada de feedback flutuante em coordenadas de tela.
##
## Responsabilidades:
## - escutar dano recebido pelo player;
## - converter posição de mundo para tela;
## - instanciar FloatingCombatText;
## - exibir números de dano próximos à Gaia.
##
## Observação:
## O arquivo foi escrito como "WordlFeedbackLayer.gd" na mensagem.
## Se esse typo existir no projeto, vale renomear para "WorldFeedbackLayer.gd"
## em uma etapa segura, revisando referências e UIDs.
extends CanvasLayer

@export_group("Scene")

## Cena usada para criar textos flutuantes.
@export var floating_combat_text_scene: PackedScene

@export_group("Player Damage")

## Grupo usado para localizar a Gaia/player.
@export var player_group_name: String = "player"

## Offset em mundo aplicado acima do player para posicionar o texto.
@export var player_damage_world_offset: Vector2 = Vector2(0.0, -60.0)

## Cor usada para dano recebido.
@export var damage_color: Color = Color(1.0, 0.04, 0.04, 1.0)

@export_group("Debug")

## Habilita logs de debug ao criar feedback.
@export var debug_feedback: bool = false

## Exibe texto de teste ao iniciar.
@export var show_test_text_on_ready: bool = false

## Root onde os textos são adicionados.
@onready var feedback_root: Control = $FeedbackRoot

## Inicializa camada e conecta evento de dano do player.
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

## Configura FeedbackRoot para ocupar a tela inteira e ignorar mouse.
func _configure_feedback_root() -> void:
	if feedback_root == null:
		return

	feedback_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_root.clip_contents = false
	feedback_root.process_mode = Node.PROCESS_MODE_ALWAYS

## Evento de dano recebido pelo player.
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

## Instancia um texto flutuante na posição de tela informada.
func spawn_floating_text(display_text: String, screen_position: Vector2, color: Color) -> void:
	if feedback_root == null:
		push_warning("[WorldFeedbackLayer] Floating damage cancelado: FeedbackRoot ausente.")
		return

	if floating_combat_text_scene == null:
		push_warning("[WorldFeedbackLayer] FloatingCombatText scene não configurada.")
		return

	# Adquire o texto flutuante do pool (reutiliza textos já finalizados).
	var instance: Node = PoolManager.spawn(floating_combat_text_scene, feedback_root)

	if not instance is Control:
		push_warning("[WorldFeedbackLayer] FloatingCombatText precisa ter root do tipo Control ou Label.")

		if instance != null:
			PoolManager.despawn(instance)

		return

	var text_control: Control = instance as Control

	# spawn já adicionou o texto ao feedback_root; aqui só posicionamos.
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

## Cria texto de teste no centro da tela.
func _spawn_debug_test_text() -> void:
	var center_position: Vector2 = get_viewport().get_visible_rect().size * 0.5

	spawn_floating_text(
		"TESTE -6",
		center_position,
		damage_color
	)

## Converte posição de mundo para posição de tela/canvas.
func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform * world_position

## Retorna o primeiro Node2D encontrado no grupo do player.
func _get_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
