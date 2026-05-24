extends Node

const GAME_TITLE: String = "Queen Survivors"
const GAME_VERSION: String = "0.1.0-module-1"

var is_debug_mode: bool = true
var default_language: String = "pt_br"

func _ready() -> void:
	DeveloperAuditLogger.log_lifecycle(
		"Boot iniciado: %s v%s"  % [GAME_TITLE, GAME_VERSION],
		"App"
	)

func get_game_title() -> String:
	return GAME_TITLE

func get_game_version() -> String:
	return GAME_VERSION 
