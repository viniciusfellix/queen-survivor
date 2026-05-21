extends Node

const SAVE_PATH: String = "user://queen_survivors_save.json"

var save_data: SaveData = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	load_or_create_save()
	_connect_events()

func get_save_data() -> SaveData:
	if save_data == null:
		load_or_create_save()

	return save_data

func load_or_create_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var loaded_successfully: bool = _load_from_disk()

		if loaded_successfully:
			GameEvents.emit_debug("[SaveManager] Save carregado.")
			GameEvents.save_loaded.emit()
			return

	_create_new_save()

func save_to_disk() -> void:
	if save_data == null:
		return

	var json_string: String = JSON.stringify(save_data.to_dictionary(), "\t")

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_warning("[SaveManager] Não foi possível abrir arquivo para escrita: %s" % SAVE_PATH)
		return

	file.store_string(json_string)
	file.close()

	GameEvents.emit_debug("[SaveManager] Save salvo em: %s" % SAVE_PATH)
	GameEvents.save_saved.emit()

func apply_run_result(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	if save_data == null:
		load_or_create_save()

	if save_data == null:
		return

	save_data.apply_run_result(result_payload)
	save_to_disk()

	GameEvents.save_updated.emit(save_data)

	GameEvents.emit_debug("[SaveManager] Resultado aplicado ao save. total_xp=%s total_money=%s completed_maps=%s" % [
		str(save_data.total_xp),
		str(save_data.total_money),
		str(save_data.completed_maps)
	])

func reset_progression_and_save() -> void:
	if save_data == null:
		load_or_create_save()

	if save_data == null:
		return

	save_data.reset_progression()
	save_to_disk()

	GameEvents.save_updated.emit(save_data)
	GameEvents.emit_debug("[SaveManager] Progressão resetada.")

func get_debug_data() -> Dictionary:
	if save_data == null:
		return {
			"has_save_data": false
		}

	return {
		"has_save_data": true,
		"save_path": SAVE_PATH,
		"save_version": save_data.save_version,
		"total_xp": save_data.total_xp,
		"total_money": save_data.total_money,
		"completed_maps": save_data.completed_maps,
		"last_run_summary": save_data.last_run_summary,
		"basic_records": save_data.basic_records,
		"sfw_enabled": save_data.sfw_enabled,
		"sfw_first_prompt_answered": save_data.sfw_first_prompt_answered
	}

func _connect_events() -> void:
	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

func _on_run_finished(result_payload: RunResultPayload) -> void:
	apply_run_result(result_payload)

func _create_new_save() -> void:
	save_data = SaveData.new()
	save_to_disk()

	GameEvents.emit_debug("[SaveManager] Novo save criado.")
	GameEvents.save_created.emit()

func _load_from_disk() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return false

	var json_string: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_string)

	if not parsed is Dictionary:
		push_warning("[SaveManager] Save inválido. Criando novo save.")
		return false

	save_data = SaveData.new()
	save_data.load_from_dictionary(parsed as Dictionary)

	return true
