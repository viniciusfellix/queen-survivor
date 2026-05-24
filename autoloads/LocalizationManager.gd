extends Node

var current_language: String = "pt_br"
var translations: Dictionary = {}

func _ready() -> void:
	load_language(current_language)

func load_language(language_code: String) -> void:
	current_language = language_code
	translations.clear()

	var path := "res://data/localization/%s.json" % language_code

	if not FileAccess.file_exists(path):
		push_warning("[LocalizationManager] Arquivo de localização não encontrado: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[LocalizationManager] Não foi possível abrir: %s" % path)
		return

	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[LocalizationManager] JSON inválido em: %s" % path)
		return

	translations = parsed
	DeveloperAuditLogger.log_lifecycle(
		"Idioma carregado: %s" % language_code,
		"LocalizationManager",
		{
			"language": language_code
		}
	)

func get_text(key: String) -> String:
	if translations.has(key):
		return str(translations[key])

	return key
