## Gerenciador simples de localização do protótipo.
##
## Responsabilidades:
## - carregar arquivo JSON de idioma;
## - armazenar traduções em memória;
## - retornar texto traduzido a partir de uma chave;
## - preservar fallback seguro retornando a própria chave quando não houver tradução.
##
## Observação:
## Este sistema usa JSON próprio.
## Existe possibilidade futura de migração para o sistema nativo de tradução do Godot,
## mas a versão atual é funcional para o protótipo.
extends Node

## Idioma atual carregado.
##
## Padrão inicial do projeto: português do Brasil.
var current_language: String = "pt_br"

## Dicionário com as traduções carregadas do arquivo JSON.
##
## Chave: identificador textual, como `ui.result.victory`.
## Valor: texto traduzido.
var translations: Dictionary = {}

## Carrega o idioma padrão ao iniciar o autoload.
func _ready() -> void:
	load_language(current_language)

## Carrega um arquivo de localização pelo código do idioma.
##
## Exemplo:
## - `pt_br` carrega `res://data/localization/pt_br.json`.
##
## Se o arquivo não existir, não quebra o jogo: apenas emite warning
## e mantém fallback de retornar as chaves.
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

## Retorna o texto traduzido para uma chave.
##
## Se a chave não existir no idioma atual, retorna a própria chave.
## Esse fallback facilita identificar textos faltantes sem quebrar a UI.
func get_text(key: String) -> String:
	if translations.has(key):
		return str(translations[key])

	return key
