## Controller responsável por criar drops físicos no mundo.
##
## Responsabilidades:
## - escutar o evento global de morte de inimigo;
## - avaliar chance de drop de moeda;
## - instanciar CoinDrop no DropRoot;
## - configurar a moeda com CoinDropDefinition, valor e referência do player;
## - impedir criação de drops quando a run já está encerrando/finalizada.
##
## Importante:
## Este controller não calcula XP e não aplica recompensa final.
## Ele cuida apenas do drop físico de moeda.
extends Node

## Cena usada para instanciar moedas físicas.
@export_file("*.tscn") var coin_drop_scene_path: String = "res://gameplay/drops/CoinDrop.tscn"

## Definition com dados de magnetismo, valor padrão, raio de coleta e debug.
@export var coin_definition: CoinDropDefinition

## Caminho opcional para o node que receberá os drops instanciados.
@export var drop_root_path: NodePath

## Grupo usado para localizar a Gaia/player.
@export var player_group_name: String = "player"

## Variação aleatória aplicada na posição da moeda ao nascer.
##
## Evita que moedas surjam todas exatamente no mesmo ponto.
@export var random_position_jitter: float = 18.0

## Root onde moedas e drops serão adicionados.
var drop_root: Node2D = null

## Referência do player usada pela moeda para magnetismo.
var player_node: Node2D = null

## Inicializa referências e conecta eventos globais.
func _ready() -> void:
	drop_root = _resolve_drop_root()
	player_node = _resolve_player()

	_connect_events()

	if drop_root != null:
		DeveloperAuditLogger.log_spawn(
			"DropRoot encontrado: %s" % drop_root.name,
			"DropController",
			{
				"drop_root": drop_root.name
			}
		)
	else:
		push_warning("[DropController] DropRoot não encontrado.")

	if coin_definition != null:
		DeveloperAuditLogger.log_spawn(
			"CoinDefinition configurada: %s" % coin_definition.id,
			"DropController",
			{
				"coin_definition_id": coin_definition.id
			}
		)
	else:
		push_warning("[DropController] CoinDefinition não configurada.")

## Conecta o controller ao evento global de morte de inimigo.
func _connect_events() -> void:
	if not GameEvents.enemy_died.is_connected(_on_enemy_died):
		GameEvents.enemy_died.connect(_on_enemy_died)

## Callback chamado quando um inimigo morre.
##
## Recebe dados suficientes para:
## - decidir se moeda deve dropar;
## - posicionar a moeda;
## - definir o valor da moeda;
## - registrar logs técnicos.
func _on_enemy_died(
	enemy_id: String,
	source_id: String,
	_xp_reward: int,
	enemy_global_position: Vector2,
	coin_drop_chance: float,
	coin_drop_value: int
) -> void:
	## Após início do encerramento, nenhum drop novo deve entrar na run.
	if RunQuery.is_run_ending(get_tree()) or RunQuery.is_run_finished(get_tree()):
		return

	if coin_drop_value <= 0:
		return

	if coin_drop_chance <= 0.0:
		return

	var roll: float = randf()

	if roll > coin_drop_chance:
		DeveloperAuditLogger.log_spawn(
			"Moeda não dropou. enemy=%s roll=%s chance=%s" % [
				enemy_id,
				str(roll),
				str(coin_drop_chance)
			],
			"DropController",
			{
				"enemy_id": enemy_id,
				"roll": roll,
				"chance": coin_drop_chance
			}
		)
		return

	call_deferred(
		"_spawn_coin",
		enemy_global_position,
		coin_drop_value,
		enemy_id,
		source_id
	)

## Instancia uma moeda física no mundo.
##
## A moeda nasce em posição próxima ao inimigo morto e recebe:
## - CoinDropDefinition;
## - valor;
## - referência do player para magnetismo.
func _spawn_coin(spawn_position: Vector2, value: int, enemy_id: String, source_id: String) -> void:
	if RunQuery.is_run_ending(get_tree()) or RunQuery.is_run_finished(get_tree()):
		return

	if drop_root == null:
		drop_root = _resolve_drop_root()

	if player_node == null:
		player_node = _resolve_player()

	if drop_root == null:
		push_warning("[DropController] Não foi possível criar moeda: DropRoot ausente.")
		return

	# Calcula a posição final antes do spawn para a moeda já nascer no lugar certo.
	var coin_spawn_position: Vector2 = spawn_position + _get_random_jitter()

	# Adquire a moeda do pool (reutiliza moedas já coletadas quando houver).
	var coin_instance: Node = PoolManager.spawn_path(coin_drop_scene_path, drop_root, coin_spawn_position)

	if not coin_instance is Node2D:
		push_warning("[DropController] CoinDrop inválida ou não é Node2D: %s" % coin_drop_scene_path)

		if coin_instance != null:
			PoolManager.despawn(coin_instance)

		return

	var coin_node: Node2D = coin_instance as Node2D

	if coin_node.has_method("setup"):
		coin_node.call("setup", coin_definition, value, player_node)

	DeveloperAuditLogger.log_spawn(
		"Moeda criada: enemy=%s source=%s value=%s pos=%s" % [
			enemy_id,
			source_id,
			str(value),
			str(coin_node.global_position)
		],
		"DropController",
		{
			"enemy_id": enemy_id,
			"source_id": source_id,
			"value": value,
			"position": coin_node.global_position
		}
	)

## Gera deslocamento aleatório circular para a posição inicial do drop.
func _get_random_jitter() -> Vector2:
	if random_position_jitter <= 0.0:
		return Vector2.ZERO

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(0.0, random_position_jitter)

	return Vector2(cos(angle), sin(angle)) * distance

## Resolve o DropRoot.
##
## Ordem:
## 1. caminho configurado no Inspector;
## 2. irmão chamado DropRoot;
## 3. DropRoot no pai do parent.
func _resolve_drop_root() -> Node2D:
	if drop_root_path != NodePath():
		var configured_root: Node = get_node_or_null(drop_root_path)

		if configured_root is Node2D:
			return configured_root as Node2D

	var parent_node: Node = get_parent()

	if parent_node != null:
		var sibling_root: Node = parent_node.get_node_or_null("DropRoot")

		if sibling_root is Node2D:
			return sibling_root as Node2D

		var parent_parent: Node = parent_node.get_parent()

		if parent_parent != null:
			var uncle_root: Node = parent_parent.get_node_or_null("DropRoot")

			if uncle_root is Node2D:
				return uncle_root as Node2D

	return null

## Localiza o primeiro Node2D no grupo do player.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
