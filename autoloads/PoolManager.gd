## Gerenciador central de object pooling do jogo.
##
## Responsabilidades:
## - manter filas de instâncias reutilizáveis agrupadas por cena (PackedScene);
## - entregar instâncias prontas via spawn()/spawn_path() e recebê-las de volta via despawn();
## - cachear o carregamento de PackedScene por caminho (evita load() a cada spawn);
## - resetar cada instância pelos hooks opcionais _on_pool_acquire()/_on_pool_release().
##
## Filas e agrupamentos:
## Cada PackedScene tem sua própria fila (Array) de nós livres, agrupada por uma chave
## (o caminho da cena). Os nós inativos ficam guardados FORA da árvore de cena, então não
## processam nem colidem enquanto esperam — é isso que permite milhares de inimigos/itens
## reaproveitando o mesmo conjunto de instâncias sem custo de criação/destruição constante.
##
## Importante:
## Um nó devolvido sai da árvore (remove_child) e volta para a fila. Nós que não vieram do
## pool (sem o metadado de chave) são liberados com queue_free() no despawn, como fallback seguro.
extends Node

## Metadado que marca a fila (chave) à qual um nó pertence.
const POOL_KEY_META: StringName = &"__pool_key"

# Filas de nós livres por chave de cena. Chave: String -> Valor: Array[Node].
var _free_nodes: Dictionary = {}

# Cache de PackedScene por caminho res:// para não dar load() repetido.
var _scene_cache: Dictionary = {}

## Retorna a PackedScene de um caminho, carregando e cacheando na primeira vez.
func get_scene(scene_path: String) -> PackedScene:
	if scene_path.is_empty():
		return null

	if _scene_cache.has(scene_path):
		return _scene_cache[scene_path] as PackedScene

	var packed_scene: PackedScene = load(scene_path) as PackedScene

	if packed_scene != null:
		_scene_cache[scene_path] = packed_scene

	return packed_scene

## Adquire uma instância da cena pelo caminho e a adiciona ao parent informado.
##
## Quando at_global_position é um Vector2, o nó já nasce nessa posição global
## (aplicada antes de entrar na árvore — ver spawn()).
func spawn_path(scene_path: String, parent: Node, at_global_position: Variant = null) -> Node:
	var packed_scene: PackedScene = get_scene(scene_path)

	if packed_scene == null:
		push_warning("[PoolManager] Cena inválida ou não encontrada: %s" % scene_path)
		return null

	return spawn(packed_scene, parent, at_global_position)

## Adquire uma instância da PackedScene, reutilizando da fila quando houver.
##
## Se at_global_position for um Vector2 (e o nó/parent forem Node2D), a posição é
## aplicada ANTES do add_child. Isso evita que o nó exista por um frame na origem
## do parent (0,0) — o que faria um corpo físico colidir/empurrar quem estiver lá
## (ex.: o player nascendo em 0,0 sendo "teleportado" pela depenetração).
func spawn(scene: PackedScene, parent: Node, at_global_position: Variant = null) -> Node:
	if scene == null or parent == null:
		return null

	var key: String = _get_scene_key(scene)
	var node: Node = _take_free_node(key)

	# Sem instância livre na fila: cria uma nova e marca a chave do pool.
	if node == null:
		node = scene.instantiate()
		node.set_meta(POOL_KEY_META, key)

	# Posiciona o nó antes de entrar na árvore, convertendo a posição global
	# desejada para a posição local relativa ao parent.
	if at_global_position is Vector2 and node is Node2D and parent is Node2D:
		var parent_node_2d: Node2D = parent as Node2D
		var target_node_2d: Node2D = node as Node2D
		target_node_2d.position = parent_node_2d.to_local(at_global_position)

	parent.add_child(node)

	# Hook opcional para o nó restaurar seu estado de "recém-criado".
	if node.has_method("_on_pool_acquire"):
		node.call("_on_pool_acquire")

	return node

## Devolve um nó ao pool, removendo-o da árvore. Fallback: queue_free() se não for poolado.
func despawn(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	# Nó que não veio do pool: libera normalmente.
	if not node.has_meta(POOL_KEY_META):
		node.queue_free()
		return

	# Hook opcional para o nó parar tweens/efeitos antes de hibernar.
	if node.has_method("_on_pool_release"):
		node.call("_on_pool_release")

	var parent: Node = node.get_parent()

	if parent != null:
		parent.remove_child(node)

	var key: String = String(node.get_meta(POOL_KEY_META))
	_get_free_list(key).append(node)

## Pré-cria instâncias e as deixa na fila, evitando hitch no primeiro uso em massa.
func prewarm(scene: PackedScene, count: int) -> void:
	if scene == null or count <= 0:
		return

	var key: String = _get_scene_key(scene)
	var free_list: Array = _get_free_list(key)

	for _i: int in range(count):
		var node: Node = scene.instantiate()
		node.set_meta(POOL_KEY_META, key)
		free_list.append(node)

## Pré-cria instâncias a partir de um caminho de cena.
func prewarm_path(scene_path: String, count: int) -> void:
	prewarm(get_scene(scene_path), count)

## Libera todas as instâncias guardadas e limpa as filas. Use ao descarregar a cena.
func clear_all() -> void:
	for key: String in _free_nodes.keys():
		var free_list: Array = _free_nodes[key]

		for node: Node in free_list:
			if is_instance_valid(node):
				node.queue_free()

	_free_nodes.clear()

## Retorna um resumo read-only do estado atual do pool para debug/profiling.
func get_debug_data() -> Dictionary:
	var free_count_by_key: Dictionary = {}
	var total_free_nodes: int = 0

	for key: String in _free_nodes.keys():
		var free_list: Array = _free_nodes[key]
		var free_count: int = free_list.size()
		free_count_by_key[key] = free_count
		total_free_nodes += free_count

	return {
		"cached_scene_count": _scene_cache.size(),
		"pooled_scene_keys": _free_nodes.keys(),
		"pooled_scene_count": _free_nodes.size(),
		"total_free_nodes": total_free_nodes,
		"free_count_by_key": free_count_by_key
	}

# Remove e retorna um nó válido da fila da chave, ou null se a fila estiver vazia.
func _take_free_node(key: String) -> Node:
	var free_list: Array = _get_free_list(key)

	while not free_list.is_empty():
		var node: Node = free_list.pop_back()

		# Ignora referências que possam ter sido liberadas por fora.
		if is_instance_valid(node):
			return node

	return null

# Retorna (criando se necessário) a fila de nós livres de uma chave.
func _get_free_list(key: String) -> Array:
	if not _free_nodes.has(key):
		_free_nodes[key] = []

	return _free_nodes[key]

# Calcula a chave de agrupamento de uma PackedScene (caminho do recurso ou id).
func _get_scene_key(scene: PackedScene) -> String:
	if not scene.resource_path.is_empty():
		return scene.resource_path

	return str(scene.get_instance_id())
