## Resource que organiza a progressão temporal de spawn de um mapa.
##
## Uma timeline contém múltiplas faixas configuráveis.
## Cada faixa define qual inimigo aparece, em que intervalo da run,
## com qual frequência e limite simultâneo.
extends Resource
class_name SpawnTimelineDefinition

## ID técnico único da timeline.
##
## Exemplo atual: `spawn_timeline_test_arena_10min`.
@export var id: String = ""

## Chave de localização opcional para nome da timeline.
@export var display_name_key: String = ""

## Faixas de spawn configuradas para diferentes momentos da run.
@export var entries: Array[SpawnTimelineEntryDefinition] = []

## Verifica se a timeline possui ID e ao menos uma faixa cadastrada.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and not entries.is_empty()

## Retorna a faixa válida que deve estar ativa no tempo informado.
##
## Quando mais de uma faixa cobre o mesmo momento, prevalece aquela
## com maior `start_time_seconds`, permitindo overrides por fase.
func get_active_entry(elapsed_seconds: float) -> SpawnTimelineEntryDefinition:
	var selected_entry: SpawnTimelineEntryDefinition = null

	for entry: SpawnTimelineEntryDefinition in entries:
		if entry == null:
			continue

		if not entry.is_valid_entry():
			continue

		if not entry.is_active_at(elapsed_seconds):
			continue

		if selected_entry == null:
			selected_entry = entry
			continue

		if entry.start_time_seconds >= selected_entry.start_time_seconds:
			selected_entry = entry

	return selected_entry

## Retorna um resumo legível das faixas para logs e auditoria.
func get_debug_summary() -> String:
	var parts: Array[String] = []

	for entry: SpawnTimelineEntryDefinition in entries:
		if entry == null:
			continue

		parts.append("%s[%s-%s]" % [
			entry.id,
			str(entry.start_time_seconds),
			str(entry.end_time_seconds)
		])

	return ", ".join(parts)
