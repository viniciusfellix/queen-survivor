extends Resource
class_name SpawnTimelineDefinition

@export var id: String = ""

@export var display_name_key: String = ""

@export var entries: Array[SpawnTimelineEntryDefinition] = []

func is_valid_definition() -> bool:
	return id.strip_edges() != "" and not entries.is_empty()

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
