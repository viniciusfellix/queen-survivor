## Autoload responsável pelas informações globais mínimas da aplicação.
##
## No Módulo 1, mantém o nome e a versão atual do protótipo e registra
## o início do boot no logger técnico estruturado.
extends Node

## Nome oficial do jogo utilizado em logs e futuras telas institucionais.
const GAME_TITLE: String = "Queen Survivors"

## Versão técnica atual do protótipo.
## Deve ser atualizada quando um módulo consolidado alterar a identificação do build.
const GAME_VERSION: String = "0.1.0-module-1"

## Inicializa o autoload e registra o boot principal da aplicação.
##
## O log pertence ao canal LIFECYCLE porque identifica o início da execução
## do jogo, sem representar uma ação específica de gameplay.
func _ready() -> void:
	DeveloperAuditLogger.log_lifecycle(
		"Boot iniciado: %s v%s" % [GAME_TITLE, GAME_VERSION],
		"App"
	)

## Retorna o nome oficial configurado para a aplicação.
func get_game_title() -> String:
	return GAME_TITLE

## Retorna a versão técnica atual do build.
func get_game_version() -> String:
	return GAME_VERSION
