extends Resource
class_name SaveData

var save_version: int = 1

# Recurso permanente de XP única.
var total_xp: int = 0

# Dinheiro permanente obtido ao final das runs.
var total_money: int = 0

# Mapas concluídos ao menos uma vez.
var completed_maps: Array[String] = []

# Último resumo de run.
var last_run_summary: Dictionary = {}

# Recordes simples.
var basic_records: Dictionary = {
	"best_survived_seconds_by_map": {},
	"best_level_by_map": {},
	"best_coins_by_map": {},
	"best_kills_by_map": {},
	"victories_by_map": {}
}

# Configurações simples previstas.
var settings: Dictionary = {
	"language": "pt_br"
}

var sfw_enabled: bool = true
var sfw_first_prompt_answered: bool = false

# Futuro:
# Não salvar apenas atributos finais.
# Salvar compras com id, nível, custo e recurso usado.
var purchased_upgrades: Dictionary = {}

func apply_run_result(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	total_xp += max(0, result_payload.run_xp_gained)
	total_money += max(0, result_payload.final_money_reward)

	if result_payload.victory:
		_mark_map_completed(result_payload.map_id)
		_increment_map_victory(result_payload.map_id)

	last_run_summary = result_payload.to_dictionary()
	_update_basic_records(result_payload)

func reset_progression() -> void:
	total_xp = 0
	total_money = 0
	completed_maps.clear()
	last_run_summary.clear()

	basic_records = {
		"best_survived_seconds_by_map": {},
		"best_level_by_map": {},
		"best_coins_by_map": {},
		"best_kills_by_map": {},
		"victories_by_map": {}
	}

	purchased_upgrades.clear()

func to_dictionary() -> Dictionary:
	return {
		"save_version": save_version,
		"total_xp": total_xp,
		"total_money": total_money,
		"completed_maps": completed_maps,
		"last_run_summary": last_run_summary,
		"basic_records": basic_records,
		"settings": settings,
		"sfw_enabled": sfw_enabled,
		"sfw_first_prompt_answered": sfw_first_prompt_answered,
		"purchased_upgrades": purchased_upgrades
	}

func load_from_dictionary(data: Dictionary) -> void:
	save_version = int(data.get("save_version", 1))

	total_xp = int(data.get("total_xp", 0))
	total_money = int(data.get("total_money", 0))

	completed_maps.clear()

	var loaded_completed_maps: Variant = data.get("completed_maps", [])

	if loaded_completed_maps is Array:
		for map_id_variant: Variant in loaded_completed_maps:
			completed_maps.append(str(map_id_variant))

	last_run_summary = _safe_dictionary(data.get("last_run_summary", {}))
	basic_records = _merge_basic_records(_safe_dictionary(data.get("basic_records", {})))
	settings = _safe_dictionary(data.get("settings", {"language": "pt_br"}))

	sfw_enabled = bool(data.get("sfw_enabled", true))
	sfw_first_prompt_answered = bool(data.get("sfw_first_prompt_answered", false))

	purchased_upgrades = _safe_dictionary(data.get("purchased_upgrades", {}))

func _mark_map_completed(map_id: String) -> void:
	if map_id.strip_edges() == "":
		return

	if completed_maps.has(map_id):
		return

	completed_maps.append(map_id)

func _update_basic_records(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	var map_id: String = result_payload.map_id

	if map_id.strip_edges() == "":
		map_id = "unknown_map"

	_set_best_float_record("best_survived_seconds_by_map", map_id, result_payload.survived_seconds)
	_set_best_int_record("best_level_by_map", map_id, result_payload.level_reached)
	_set_best_int_record("best_coins_by_map", map_id, result_payload.run_coins_collected)
	_set_best_int_record("best_kills_by_map", map_id, result_payload.enemies_killed)

func _increment_map_victory(map_id: String) -> void:
	if map_id.strip_edges() == "":
		return

	var victories: Dictionary = _get_record_dictionary("victories_by_map")
	var current_value: int = int(victories.get(map_id, 0))

	victories[map_id] = current_value + 1
	basic_records["victories_by_map"] = victories

func _set_best_int_record(record_key: String, map_id: String, value: int) -> void:
	var record: Dictionary = _get_record_dictionary(record_key)
	var previous_value: int = int(record.get(map_id, 0))

	if value > previous_value:
		record[map_id] = value

	basic_records[record_key] = record

func _set_best_float_record(record_key: String, map_id: String, value: float) -> void:
	var record: Dictionary = _get_record_dictionary(record_key)
	var previous_value: float = float(record.get(map_id, 0.0))

	if value > previous_value:
		record[map_id] = value

	basic_records[record_key] = record

func _get_record_dictionary(record_key: String) -> Dictionary:
	var record_variant: Variant = basic_records.get(record_key, {})

	if record_variant is Dictionary:
		return record_variant as Dictionary

	return {}

func _merge_basic_records(loaded_records: Dictionary) -> Dictionary:
	var merged: Dictionary = {
		"best_survived_seconds_by_map": {},
		"best_level_by_map": {},
		"best_coins_by_map": {},
		"best_kills_by_map": {},
		"victories_by_map": {}
	}

	for key: String in merged.keys():
		var value: Variant = loaded_records.get(key, {})

		if value is Dictionary:
			merged[key] = value

	return merged

func _safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}
