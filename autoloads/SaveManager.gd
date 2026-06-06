## Gerenciador global de save do protótipo.
##
## Responsabilidades:
## - carregar save existente;
## - criar save novo quando não houver arquivo válido;
## - salvar progresso em disco;
## - aplicar resultado de run;
## - resetar progressão permanente;
## - fornecer dados técnicos para debug;
## - emitir events relacionados a save.
##
## Importante:
## Este manager lida com progresso permanente.
## O estado temporário da run pertence ao RunState, não ao SaveManager.
extends Node

## Caminho do arquivo de save no armazenamento do usuário.
const SAVE_PATH: String = "user://queen_survivors_save.json"

## Instância atual dos dados persistentes carregados em memória.
var save_data: SaveData = null

## Inicializa o save e conecta eventos globais.
func _ready() -> void:
	## Mantém o SaveManager processando mesmo se a árvore for pausada.
	## Isso é útil para telas de resultado, menus técnicos e persistência.
	process_mode = Node.PROCESS_MODE_ALWAYS

	load_or_create_save()
	_connect_events()

## Retorna a instância atual de SaveData.
##
## Se ainda não existir save carregado, tenta carregar ou criar.
func get_save_data() -> SaveData:
	if save_data == null:
		load_or_create_save()

	return save_data

## Carrega um save existente ou cria um novo.
##
## Fluxo:
## - se o arquivo existe, tenta carregar;
## - se carregar com sucesso, usa esse save;
## - se falhar ou não existir, cria um novo save.
func load_or_create_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var loaded_successfully: bool = _load_from_disk()

		if loaded_successfully:
			DeveloperAuditLogger.log_save(
				"Save carregado.",
				"SaveManager",
				{
					"path": SAVE_PATH
				}
			)
			return

	_create_new_save()

## Salva o SaveData atual em disco.
##
## Retorna true quando o arquivo foi escrito com sucesso.
func save_to_disk() -> bool:
	if save_data == null:
		return false

	var json_string: String = JSON.stringify(save_data.to_dictionary(), "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_warning("[SaveManager] Não foi possível abrir arquivo para escrita: %s" % SAVE_PATH)
		return false

	file.store_string(json_string)
	file.close()

	DeveloperAuditLogger.log_save(
		"Save salvo em: %s" % SAVE_PATH,
		"SaveManager",
		{
			"path": SAVE_PATH
		}
	)

	return true

## Aplica o resultado final de uma run ao save permanente.
##
## Responsabilidades:
## - adicionar XP/dinheiro conforme RunResultPayload;
## - registrar mapa concluído quando aplicável;
## - atualizar resumo/recordes básicos dentro do SaveData;
## - salvar em disco;
## - emitir signals para UI e painel de resultado.
func apply_run_result(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	if save_data == null:
		load_or_create_save()

	if save_data == null:
		return

	save_data.apply_run_result(result_payload)

	var saved_successfully: bool = save_to_disk()

	## Informa consumidores gerais que o save em memória foi atualizado.
	GameEvents.save_updated.emit(save_data)

	## Informa especificamente que o resultado desta run foi processado
	## e se foi persistido em disco com sucesso.
	GameEvents.run_result_persisted.emit(result_payload, save_data, saved_successfully)

	DeveloperAuditLogger.log_save(
		"Resultado aplicado. success=%s total_xp=%s total_money=%s completed_maps=%s" % [
			str(saved_successfully),
			str(save_data.total_xp),
			str(save_data.total_money),
			str(save_data.completed_maps)
		],
		"SaveManager",
		{
			"succeeded": saved_successfully,
			"total_xp": save_data.total_xp,
			"total_money": save_data.total_money,
			"completed_maps": save_data.completed_maps.duplicate()
		}
	)

## Reseta a progressão permanente e salva em disco.
##
## Usado por ferramenta técnica com confirmação visual.
## A run atual não deve ser encerrada automaticamente por esse reset.
func reset_progression_and_save() -> void:
	if save_data == null:
		load_or_create_save()

	if save_data == null:
		return

	save_data.reset_progression()

	var saved_successfully: bool = save_to_disk()

	GameEvents.save_updated.emit(save_data)

	if saved_successfully:
		DeveloperAuditLogger.log_save(
			"Progressão resetada.",
			"SaveManager",
			{
				"succeeded": saved_successfully
			}
		)
	else:
		push_warning("[SaveManager] Progressão resetada em memória, mas não foi salva em disco.")

## Retorna informações resumidas do save para ferramentas técnicas.
##
## Usado pelo DebugOverlay/PrototypeToolsPanel sem expor diretamente o objeto SaveData.
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

## Conecta o SaveManager aos events globais necessários.
func _connect_events() -> void:
	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Callback chamado quando a run termina.
##
## O RunController emite `run_finished` com um RunResultPayload.
## O SaveManager apenas aplica e persiste esse resultado.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	apply_run_result(result_payload)

## Cria uma nova instância de SaveData e tenta salvar em disco.
func _create_new_save() -> void:
	save_data = SaveData.new()

	var saved_successfully: bool = save_to_disk()

	if saved_successfully:
		DeveloperAuditLogger.log_save(
			"Novo save criado.",
			"SaveManager",
			{
				"path": SAVE_PATH
			}
		)
	else:
		push_warning("[SaveManager] Novo save criado em memória, mas não foi salvo em disco.")

## Carrega o arquivo de save do disco.
##
## Retorna true quando:
## - o arquivo abriu corretamente;
## - o JSON foi parseado;
## - o conteúdo era um Dictionary válido.
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
