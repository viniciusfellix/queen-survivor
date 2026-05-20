extends Node

const SAVE_PATH: String = "user://save_data.json"
const SAVE_VERSION: int = 1

var save_data: Dictionary = {}

func _ready() -> void:
	load_or_create_save()

func load_or_create_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		load_save()
	else:
		create_new_save()

func create_new_save() -> void:
	save_data = _get_default_save_data()
	save_save_data()
	GameEvents.save_created.emit()
	print("[SaveManager] Novo save criado.")

func load_save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[SaveManager] Falha ao abrir save. Criando novo save.")
		create_new_save()
		return

	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Save inválido. Criando novo save.")
		create_new_save()
		return

	save_data = parsed
	_migrate_if_needed()
	GameEvents.save_loaded.emit()
	print("[SaveManager] Save carregado.")

func save_save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[SaveManager] Falha ao salvar em: %s" % SAVE_PATH)
		return

	file.store_string(JSON.stringify(save_data, "\t"))
	GameEvents.save_saved.emit()

func add_total_xp(amount: int) -> void:
	if amount <= 0:
		return

	save_data["total_xp"] = int(save_data.get("total_xp", 0)) + amount
	save_save_data()

func add_total_money(amount: int) -> void:
	if amount <= 0:
		return

	save_data["total_money"] = int(save_data.get("total_money", 0)) + amount
	save_save_data()

func set_last_run_summary(summary: Dictionary) -> void:
	save_data["last_run_summary"] = summary
	save_save_data()

func _get_default_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"total_xp": 0,
		"total_money": 0,
		"unlocked_queens": ["gaia"],
		"completed_maps": [],
		"settings": {
			"language": "pt_br",
			"sfw_enabled": true,
			"sfw_first_prompt_answered": false
		},
		"basic_records": {},
		"last_run_summary": null,
		"purchased_upgrades": []
	}

func _migrate_if_needed() -> void:
	var version := int(save_data.get("version", 0))

	if version < SAVE_VERSION:
		save_data["version"] = SAVE_VERSION
		save_save_data()
