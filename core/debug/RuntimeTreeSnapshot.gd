## Utilitário para gerar uma captura textual da árvore runtime atual.
##
## Responsabilidades:
## - percorrer a árvore de nodes em execução;
## - listar nomes, classes, paths relativos, scripts e grupos;
## - compactar subárvores internas do Spine para evitar overflow no console;
## - limitar profundidade e quantidade de nodes impressos;
## - gerar resumo de grupos importantes.
##
## Uso típico:
## - acionado por ferramenta técnica/QA;
## - copiado para área de transferência;
## - usado para analisar se cenas, nodes e grupos foram montados corretamente.
##
## Este utilitário não altera gameplay.
extends RefCounted

## Limite máximo de nodes impressos no snapshot.
##
## Evita travar ou poluir o console em cenas com muitos nodes.
const MAX_PRINTED_NODES: int = 220

## Profundidade máxima de recursão exibida.
const MAX_DEPTH: int = 16

## Linha visual usada no cabeçalho.
const HEADER_LINE: String = "=============================================================================================================="

## Linha visual usada em seções de resumo.
const SUMMARY_LINE: String = "--------------------------------------------------------------------------------------------------------------"

## Contador de nodes efetivamente impressos.
var printed_nodes: int = 0

## Quantidade de subárvores Spine compactadas.
var compacted_spine_subtrees: int = 0

## Quantidade de nodes internos do Spine omitidos.
var omitted_spine_nodes: int = 0

## Quantidade de nodes omitidos por exceder limite máximo.
var omitted_by_limit: int = 0

## Quantidade de nodes omitidos por exceder profundidade máxima.
var omitted_by_depth: int = 0

## Gera snapshot textual da árvore a partir de um root.
##
## Parâmetros:
## - root: node inicial da captura;
## - include_scripts: se deve exibir script anexado;
## - include_groups: se deve exibir grupos públicos do node.
func build_snapshot(
	root: Node,
	include_scripts: bool = true,
	include_groups: bool = true
) -> String:
	if root == null:
		return "QUEEN SURVIVORS - RUNTIME TREE SNAPSHOT\nRoot ausente."

	_reset_counters()

	var lines: Array[String] = []
	var total_nodes: int = _count_nodes(root)

	lines.append("QUEEN SURVIVORS - RUNTIME TREE SNAPSHOT")
	lines.append(HEADER_LINE)
	lines.append("Root: %s" % str(root.name))
	lines.append("Scene file: %s" % root.scene_file_path)
	lines.append("Total de nodes runtime bruto: %s" % str(total_nodes))
	lines.append("Compactacao Spine habilitada: true")
	lines.append("Limite maximo de nodes impressos: %s" % str(MAX_PRINTED_NODES))
	lines.append(HEADER_LINE)
	lines.append("")

	_append_node(
		root,
		root,
		lines,
		0,
		include_scripts,
		include_groups
	)

	lines.append("")
	lines.append("RESUMO DE FILTROS DO SNAPSHOT")
	lines.append(SUMMARY_LINE)
	lines.append("Nodes impressos: %s" % str(printed_nodes))
	lines.append("Subtrees Spine compactados: %s" % str(compacted_spine_subtrees))
	lines.append("Nodes internos Spine omitidos: %s" % str(omitted_spine_nodes))
	lines.append("Nodes omitidos por limite: %s" % str(omitted_by_limit))
	lines.append("Nodes omitidos por profundidade: %s" % str(omitted_by_depth))

	return "\n".join(lines)

## Gera resumo quantitativo de grupos runtime importantes.
##
## Útil para saber rapidamente quantos players, inimigos, drops ou moedas
## existem na cena em determinado momento.
func build_group_summary(scene_tree: SceneTree) -> String:
	if scene_tree == null:
		return "QUEEN SURVIVORS - RUNTIME GROUP SUMMARY\nSceneTree ausente."

	var tracked_groups: Array[String] = [
		"player",
		"enemy",
		"run_controller",
		"drop",
		"coin_drop"
	]

	var lines: Array[String] = []

	lines.append("QUEEN SURVIVORS - RUNTIME GROUP SUMMARY")
	lines.append(HEADER_LINE)

	for group_name: String in tracked_groups:
		var grouped_nodes: Array[Node] = scene_tree.get_nodes_in_group(group_name)

		lines.append("%s: %s" % [
			group_name,
			str(grouped_nodes.size())
		])

	return "\n".join(lines)

## Reseta contadores antes de montar novo snapshot.
func _reset_counters() -> void:
	printed_nodes = 0
	compacted_spine_subtrees = 0
	omitted_spine_nodes = 0
	omitted_by_limit = 0
	omitted_by_depth = 0

## Adiciona um node e seus filhos ao snapshot.
##
## A função é recursiva e respeita:
## - limite máximo de nodes impressos;
## - profundidade máxima;
## - compactação especial para SpineSprite.
func _append_node(
	node: Node,
	root: Node,
	lines: Array[String],
	depth: int,
	include_scripts: bool,
	include_groups: bool
) -> void:
	if printed_nodes >= MAX_PRINTED_NODES:
		omitted_by_limit += _count_nodes(node)
		return

	var indentation: String = "  ".repeat(depth)
	var relative_path: String = "."

	if node != root:
		relative_path = str(root.get_path_to(node))

	var details: Array[String] = []

	if include_scripts:
		var script_path: String = _get_script_path(node)

		if script_path != "":
			details.append("script: %s" % script_path)

	if include_groups:
		var groups_text: String = _get_groups_text(node)

		if groups_text != "":
			details.append("groups: %s" % groups_text)

	var suffix: String = ""

	if not details.is_empty():
		suffix = " | " + " | ".join(details)

	lines.append("%s- %s <%s> [path: %s]%s" % [
		indentation,
		str(node.name),
		node.get_class(),
		relative_path,
		suffix
	])

	printed_nodes += 1

	## SpineSprite costuma criar muitos nodes internos runtime.
	## Compactar essa subárvore evita overflow do console e deixa a saída legível.
	if node.get_class() == "SpineSprite":
		_append_spine_summary(node, lines, indentation)
		return

	if depth >= MAX_DEPTH:
		var hidden_nodes: int = _count_nodes(node) - 1

		if hidden_nodes > 0:
			lines.append("%s  [Subtree omitido por profundidade maxima: %s nodes]" % [
				indentation,
				str(hidden_nodes)
			])

			omitted_by_depth += hidden_nodes

		return

	for child: Node in node.get_children():
		_append_node(
			child,
			root,
			lines,
			depth + 1,
			include_scripts,
			include_groups
		)

## Adiciona uma linha compactada representando nodes internos do Spine.
func _append_spine_summary(
	spine_sprite: Node,
	lines: Array[String],
	indentation: String
) -> void:
	var class_counts: Dictionary = {}
	var hidden_nodes: int = _count_descendants_by_class(spine_sprite, class_counts)

	if hidden_nodes <= 0:
		return

	lines.append("%s  [Spine runtime compactado: %s nodes internos | %s]" % [
		indentation,
		str(hidden_nodes),
		_format_class_counts(class_counts)
	])

	compacted_spine_subtrees += 1
	omitted_spine_nodes += hidden_nodes

## Conta descendentes de um node agrupando por classe.
##
## Usado principalmente para resumir o que existe dentro de SpineSprite.
func _count_descendants_by_class(
	root: Node,
	class_counts: Dictionary
) -> int:
	var total: int = 0

	for child: Node in root.get_children():
		var class_name_value: String = child.get_class()
		var existing_count: int = int(class_counts.get(class_name_value, 0))

		class_counts[class_name_value] = existing_count + 1

		total += 1
		total += _count_descendants_by_class(child, class_counts)

	return total

## Formata a contagem de classes em texto legível.
func _format_class_counts(class_counts: Dictionary) -> String:
	if class_counts.is_empty():
		return "sem nodes internos"

	var class_names: Array[String] = []

	for class_name_variant: Variant in class_counts.keys():
		class_names.append(str(class_name_variant))

	class_names.sort()

	var formatted_values: Array[String] = []

	for class_name_value: String in class_names:
		formatted_values.append("%s=%s" % [
			class_name_value,
			str(int(class_counts.get(class_name_value, 0)))
		])

	return ", ".join(formatted_values)

## Retorna caminho do script anexado ao node.
##
## Se não houver script, retorna string vazia.
func _get_script_path(node: Node) -> String:
	var attached_script: Variant = node.get_script()

	if not attached_script is Script:
		return ""

	var script_resource: Script = attached_script as Script

	return script_resource.resource_path

## Retorna grupos públicos do node em formato textual.
##
## Grupos internos do Godot, iniciados por "_", são ignorados.
func _get_groups_text(node: Node) -> String:
	var group_names: Array[String] = []

	for group_variant: Variant in node.get_groups():
		var group_name_value: String = str(group_variant)

		if group_name_value.begins_with("_"):
			continue

		group_names.append(group_name_value)

	return ", ".join(group_names)

## Conta recursivamente todos os nodes abaixo de um root, incluindo o próprio root.
func _count_nodes(root: Node) -> int:
	var total: int = 1

	for child: Node in root.get_children():
		total += _count_nodes(child)

	return total
