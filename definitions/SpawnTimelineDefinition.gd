## Resource que define a timeline de spawn de um mapa.
##
## Responsabilidades:
## - agrupar entradas de spawn;
## - escolher qual entrada está ativa com base no tempo da run;
## - fornecer resumo técnico para debug.
##
## Cada mapa pode apontar para uma SpawnTimelineDefinition diferente.
extends Resource
class_name SpawnTimelineDefinition

## ID técnico único da timeline.
@export var id: String = ""

## Chave de localização para nome/descrição da timeline, se necessário.
@export var display_name_key: String = ""

## Entradas de spawn configuradas.
##
## Cada entrada representa uma faixa de tempo com inimigo, intervalo,
## limite de inimigos vivos e distância de spawn.
@export var entries: Array[SpawnTimelineEntryDefinition] = []

## Verifica se a timeline possui configuração mínima válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and not entries.is_empty()

## Retorna a entrada ativa para determinado tempo da run.
##
## Se mais de uma entrada estiver ativa, escolhe a que começou mais tarde.
## Isso permite sobrepor ou substituir fases de spawn por tempo.
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

## Retorna resumo textual das entries configuradas.
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
