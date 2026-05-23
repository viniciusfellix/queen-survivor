@tool
extends EditorScript

## Exporta a estrutura de todas as cenas do projeto para um arquivo TXT.
##
## O relatório contém:
## - Cenas encontradas.
## - Árvore de nós de cada cena.
## - Tipo de cada nó.
## - Caminho do script anexado a cada nó.
## - Código-fonte dos scripts anexados, deduplicado ao final do relatório.
##
## Compatível com Godot 4.x.

const OUTPUT_DIR := "res://_audit_export"
const OUTPUT_FILE := OUTPUT_DIR + "/godot_project_structure.txt"

## true  = inclui o conteúdo integral dos scripts no TXT.
## false = inclui apenas o caminho dos scripts anexados.
const INCLUDE_SCRIPT_SOURCE := true

const SCENE_EXTENSIONS := ["tscn", "scn"]

## Diretórios que não devem ser varridos.
const IGNORED_DIRECTORIES := [
	".godot",
	".git",
	".import",
	"_audit_export"
]

var _scene_paths: Array[String] = []
var _attached_scripts: Dictionary = {}
var _warnings: Array[String] = []


func _run() -> void:
	_scene_paths.clear()
	_attached_scripts.clear()
	_warnings.clear()

	_collect_scene_paths("res://")
	_scene_paths.sort()

	var lines: Array[String] = []

	_append_header(lines)

	for scene_path in _scene_paths:
		_append_scene_report(scene_path, lines)

	_append_scripts_report(lines)
	_append_warnings(lines)

	_save_report(lines)


func _append_header(lines: Array[String]) -> void:
	lines.append("GODOT PROJECT STRUCTURE EXPORT")
	lines.append("=".repeat(110))
	lines.append("Gerado em: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("Projeto: %s" % ProjectSettings.globalize_path("res://"))
	lines.append("Total de cenas encontradas: %d" % _scene_paths.size())
	lines.append("Inclui conteúdo dos scripts: %s" % str(INCLUDE_SCRIPT_SOURCE))
	lines.append("")
	lines.append("OBSERVAÇÃO:")
	lines.append("Cada cena é analisada individualmente a partir do conteúdo salvo no arquivo da cena.")
	lines.append("Cenas instanciadas aparecem como referência na cena-pai e também possuem seu próprio bloco detalhado.")
	lines.append("")
	lines.append("=".repeat(110))
	lines.append("")


func _collect_scene_paths(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)

	if directory == null:
		_warnings.append("Não foi possível acessar o diretório: %s" % directory_path)
		return

	directory.list_dir_begin()

	var item_name := directory.get_next()

	while item_name != "":
		var full_path := directory_path.path_join(item_name)

		if directory.current_is_dir():
			if not item_name in IGNORED_DIRECTORIES and not item_name.begins_with("."):
				_collect_scene_paths(full_path)
		else:
			var extension := item_name.get_extension().to_lower()

			if extension in SCENE_EXTENSIONS:
				_scene_paths.append(full_path)

		item_name = directory.get_next()

	directory.list_dir_end()


func _append_scene_report(scene_path: String, lines: Array[String]) -> void:
	var packed_scene := ResourceLoader.load(scene_path, "PackedScene") as PackedScene

	if packed_scene == null:
		_warnings.append("Não foi possível carregar a cena: %s" % scene_path)
		return

	var state := packed_scene.get_state()

	lines.append("")
	lines.append("CENA: %s" % scene_path)
	lines.append("-".repeat(110))

	if state.get_node_count() == 0:
		lines.append("[Cena sem nós salvos]")
		return

	for node_index: int in state.get_node_count():
		var node_path := String(state.get_node_path(node_index))
		var node_name := String(state.get_node_name(node_index))
		var node_type := _resolve_node_type(state, node_index)
		var indentation := "  ".repeat(_calculate_depth(node_path))

		var details := ""

		var instanced_scene: PackedScene = state.get_node_instance(node_index)
		if instanced_scene != null:
			var instance_path := instanced_scene.resource_path

			if instance_path.is_empty():
				details += " | instance: [cena embutida]"
			else:
				details += " | instance: %s" % instance_path

		var attached_script := _find_attached_script(state, node_index)

		if attached_script != null:
			var script_identifier := _get_script_identifier(
				attached_script,
				scene_path,
				node_path
			)

			details += " | script: %s" % script_identifier
			_register_script(script_identifier, attached_script)

		lines.append(
			"%s- %s <%s> [path: %s]%s"
			% [
				indentation,
				node_name,
				node_type,
				node_path,
				details
			]
		)


func _resolve_node_type(state: SceneState, node_index: int) -> String:
	var node_type := String(state.get_node_type(node_index))

	if not node_type.is_empty():
		return node_type

	## Em alguns casos, o nó representa a raiz de uma cena instanciada.
	## Nessa situação, recuperamos o tipo da raiz da cena original.
	var instanced_scene: PackedScene = state.get_node_instance(node_index)

	if instanced_scene != null:
		var instance_state: SceneState = instanced_scene.get_state()

		if instance_state.get_node_count() > 0:
			var instance_root_type := String(instance_state.get_node_type(0))

			if not instance_root_type.is_empty():
				return "%s [instanced root]" % instance_root_type

		return "PackedSceneInstance"

	return "UnknownType"


func _find_attached_script(state: SceneState, node_index: int) -> Script:
	for property_index: int in state.get_node_property_count(node_index):
		var property_name: StringName = state.get_node_property_name(node_index, property_index)

		if property_name == &"script":
			var property_value: Variant = state.get_node_property_value(node_index, property_index)

			if property_value is Script:
				return property_value as Script

	return null


func _get_script_identifier(script: Script, scene_path: String, node_path: String) -> String:
	if not script.resource_path.is_empty():
		return script.resource_path

	return "%s::built_in_script::%s" % [scene_path, node_path]


func _register_script(script_identifier: String, script: Script) -> void:
	if not _attached_scripts.has(script_identifier):
		_attached_scripts[script_identifier] = script


func _append_scripts_report(lines: Array[String]) -> void:
	lines.append("")
	lines.append("")
	lines.append("SCRIPTS ANEXADOS AOS NÓS")
	lines.append("=".repeat(110))
	lines.append("Total de scripts únicos encontrados: %d" % _attached_scripts.size())

	var script_identifiers: Array = _attached_scripts.keys()
	script_identifiers.sort()

	for script_identifier in script_identifiers:
		var script := _attached_scripts[script_identifier] as Script

		lines.append("")
		lines.append("SCRIPT: %s" % script_identifier)
		lines.append("-".repeat(110))

		if not INCLUDE_SCRIPT_SOURCE:
			lines.append("[Conteúdo omitido porque INCLUDE_SCRIPT_SOURCE está configurado como false]")
			continue

		var source_code := script.get_source_code()

		## Fallback para scripts externos, caso o recurso não exponha o fonte diretamente.
		if source_code.is_empty() \
		and not script.resource_path.is_empty() \
		and FileAccess.file_exists(script.resource_path):
			source_code = FileAccess.get_file_as_string(script.resource_path)

		if source_code.is_empty():
			lines.append("[Código-fonte não disponível para este script]")
		else:
			lines.append(source_code)


func _append_warnings(lines: Array[String]) -> void:
	if _warnings.is_empty():
		return

	lines.append("")
	lines.append("")
	lines.append("AVISOS DA EXPORTAÇÃO")
	lines.append("=".repeat(110))

	for warning in _warnings:
		lines.append("- %s" % warning)


func _calculate_depth(node_path: String) -> int:
	if node_path.is_empty() or node_path == ".":
		return 0

	return node_path.count("/") + 1


func _save_report(lines: Array[String]) -> void:
	var create_directory_error: Error = DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	if create_directory_error != OK and create_directory_error != ERR_ALREADY_EXISTS:
		push_error("Não foi possível criar o diretório de exportação: %s" % OUTPUT_DIR)
		return

	var file: FileAccess = FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)

	if file == null:
		push_error("Não foi possível criar o arquivo: %s" % OUTPUT_FILE)
		return

	file.store_string("\n".join(lines))
	file.close()

	print("")
	print("============================================================")
	print("Exportação concluída com sucesso.")
	print("Arquivo gerado em: %s" % OUTPUT_FILE)
	print("Cenas exportadas: %d" % _scene_paths.size())
	print("Scripts anexados encontrados: %d" % _attached_scripts.size())
	print("============================================================")
	print("")
