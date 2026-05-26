## Gerenciador provisório de localização do protótipo.
##
## Carrega um arquivo JSON de idioma e disponibiliza textos por chave.
## O sistema está funcional para o Módulo 1, embora exista decisão futura
## de avaliar migração para o sistema nativo de tradução do Godot.
extends Node

## Código do idioma atualmente carregado.
var current_language: String = "pt_br"

## Dicionário em memória com as chaves e textos do idioma ativo.
var translations: Dictionary = {}

## Carrega o idioma padrão assim que o autoload entra na árvore.
func _ready() -> void:
	load_language(current_language)

## Carrega para memória o arquivo JSON correspondente ao idioma solicitado.
##
## Em caso de arquivo ausente, falha de leitura ou JSON inválido, mantém
## o gerenciador ativo, mas emite warning para diagnóstico.
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

## Retorna o texto localizado para a chave informada.
##
## Quando a chave não existe no idioma atual, retorna a própria chave.
## Esse fallback facilita localizar textos ainda não cadastrados durante testes.
func get_text(key: String) -> String:
	if translations.has(key):
		return str(translations[key])

	return key
