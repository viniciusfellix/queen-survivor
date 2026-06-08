## Resource que define a timeline de spawn de um mapa.
##
## Responsabilidades:
## - agrupar entries de spawn;
## - listar entries potencialmente ativas por tempo;
## - manter compatibilidade com consulta legacy de uma unica entry ativa;
## - fornecer resumo tecnico para debug.
extends Resource
class_name SpawnTimelineDefinition

## ID tecnico unico da timeline.
@export var id: String = ""

## Chave de localizacao para nome/descricao da timeline, se necessario.
@export var display_name_key: String = ""

## Entradas de spawn configuradas.
@export var entries: Array[SpawnTimelineEntryDefinition] = []

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and not entries.is_empty()

## Retorna a entrada ativa legacy para determinado tempo da run.
##
## Se mais de uma entry estiver ativa, escolhe a que comecou mais tarde.
func get_active_entry(elapsed_seconds: float) -> SpawnTimelineEntryDefinition:
	var active_entries: Array[SpawnTimelineEntryDefinition] = get_active_entries(elapsed_seconds)
	var selected_entry: SpawnTimelineEntryDefinition = null

	for entry: SpawnTimelineEntryDefinition in active_entries:
		if selected_entry == null:
			selected_entry = entry
			continue

		if entry.get_effective_start_time_min_seconds() >= selected_entry.get_effective_start_time_min_seconds():
			selected_entry = entry

	return selected_entry

## Retorna todas as entries potencialmente ativas em determinado tempo da run.
func get_active_entries(elapsed_seconds: float) -> Array[SpawnTimelineEntryDefinition]:
	var active_entries: Array[SpawnTimelineEntryDefinition] = []

	for entry: SpawnTimelineEntryDefinition in entries:
		if entry == null:
			continue

		if not entry.is_valid_entry():
			continue

		if not entry.is_active_at(elapsed_seconds):
			continue

		active_entries.append(entry)

	return active_entries

func get_debug_summary() -> String:
	var parts: Array[String] = []

	for entry: SpawnTimelineEntryDefinition in entries:
		if entry == null:
			continue

		parts.append("%s[%s-%s]" % [
			entry.id,
			str(entry.get_effective_start_time_min_seconds()),
			str(entry.get_effective_end_time_max_seconds())
		])

	return ", ".join(parts)
