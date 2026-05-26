## Controller responsável por transformar mortes de inimigos em drops físicos.
##
## No Módulo 1, administra exclusivamente moedas:
## - escuta morte de inimigos;
## - realiza sorteio de drop;
## - instancia `CoinDrop`;
## - posiciona a moeda com pequeno deslocamento visual;
## - injeta referências necessárias para magnetismo e coleta.
extends Node

## Cena utilizada para instanciar uma moeda física.
@export_file("*.tscn") var coin_drop_scene_path: String = "res://gameplay/drops/CoinDrop.tscn"

## Definition com valores base de magnetismo, coleta e aparência da moeda.
@export var coin_definition: CoinDropDefinition

## Caminho opcional para o container onde drops serão inseridos.
@export var drop_root_path: NodePath

## Grupo utilizado para localizar a Queen que atrairá as moedas.
@export var player_group_name: String = "player"

## Variação aleatória aplicada à posição de nascimento da moeda.
##
## Evita que múltiplos drops fiquem visualmente perfeitamente sobrepostos.
@export var random_position_jitter: float = 18.0

## Container runtime dos drops físicos.
var drop_root: Node2D = null

## Referência runtime da Queen.
var player_node: Node2D = null

## Resolve dependências iniciais e conecta o evento de morte de inimigos.
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

## Conecta os sinais necessários para criar drops após mortes.
func _connect_events() -> void:
	if not GameEvents.enemy_died.is_connected(_on_enemy_died):
		GameEvents.enemy_died.connect(_on_enemy_died)

## Processa a chance de drop de moeda após a morte de um inimigo.
##
## Não cria novas moedas depois que a run entrou em encerramento
## ou já exibiu resultado final.
func _on_enemy_died(
	enemy_id: String,
	source_id: String,
	_xp_reward: int,
	enemy_global_position: Vector2,
	coin_drop_chance: float,
	coin_drop_value: int
) -> void:
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

	_spawn_coin(enemy_global_position, coin_drop_value, enemy_id, source_id)

## Instancia uma moeda física na posição da morte do inimigo.
##
## A moeda recebe definition, valor e player atual.
## O saldo da run somente será atualizado depois da coleta efetiva.
func _spawn_coin(spawn_position: Vector2, value: int, enemy_id: String, source_id: String) -> void:
	if drop_root == null:
		drop_root = _resolve_drop_root()

	if player_node == null:
		player_node = _resolve_player()

	if drop_root == null:
		push_warning("[DropController] Não foi possível criar moeda: DropRoot ausente.")
		return

	var packed_coin: PackedScene = load(coin_drop_scene_path) as PackedScene

	if packed_coin == null:
		push_warning("[DropController] Não foi possível carregar CoinDrop: %s" % coin_drop_scene_path)
		return

	var coin_instance: Node = packed_coin.instantiate()

	if not coin_instance is Node2D:
		push_warning("[DropController] CoinDrop não é Node2D.")
		coin_instance.queue_free()
		return

	var coin_node: Node2D = coin_instance as Node2D

	drop_root.add_child(coin_node)
	coin_node.global_position = spawn_position + _get_random_jitter()

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

## Gera pequeno deslocamento aleatório para a posição visual do drop.
func _get_random_jitter() -> Vector2:
	if random_position_jitter <= 0.0:
		return Vector2.ZERO

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(0.0, random_position_jitter)

	return Vector2(cos(angle), sin(angle)) * distance

## Resolve o container de drops da cena atual.
##
## Prioridade:
## 1. caminho configurado;
## 2. irmão direto chamado `DropRoot`;
## 3. container encontrado um nível acima.
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

## Resolve a Queen responsável por atrair e coletar moedas.
func _resolve_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(player_group_name)

	for node: Node in players:
		if node is Node2D:
			return node as Node2D

	return null
