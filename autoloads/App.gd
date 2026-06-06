## Autoload principal da aplicação.
##
## Responsabilidades:
## - centralizar informações globais simples do jogo;
## - registrar o início do boot nos logs técnicos;
## - disponibilizar título e versão atual para outros sistemas.
##
## Importante:
## Este script não deve conter regra de gameplay.
## Ele funciona como ponto global de identificação da aplicação.
extends Node

## Nome oficial do jogo.
const GAME_TITLE: String = "Queen Survivors"

## Versão técnica atual do protótipo/módulo.
const GAME_VERSION: String = "0.1.0-module-1"

## Executado quando o autoload entra na árvore.
##
## Registra no DeveloperAuditLogger que o boot da aplicação começou.
func _ready() -> void:
	# Define a locale do projeto usando o sistema nativo de tradução do Godot.
	# Futuramente a locale pode vir de SaveData.settings; por ora mantém pt_BR.
	TranslationServer.set_locale("pt_BR")

	DeveloperAuditLogger.log_lifecycle(
		"Boot iniciado: %s v%s" % [GAME_TITLE, GAME_VERSION],
		"App"
	)

## Retorna o nome oficial do jogo.
func get_game_title() -> String:
	return GAME_TITLE

## Retorna a versão técnica atual.
func get_game_version() -> String:
	return GAME_VERSION
