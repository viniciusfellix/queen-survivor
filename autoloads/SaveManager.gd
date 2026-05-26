## Serviço global responsável pela persistência do progresso permanente.
##
## Responsabilidades atuais:
## - carregar ou criar o save ao iniciar o jogo;
## - salvar o estado permanente em arquivo JSON;
## - aplicar o resultado concluído de uma run;
## - resetar progressão permanente por ferramenta de protótipo;
## - emitir eventos para atualizar interfaces após persistência.
##
## O formato JSON é válido para o protótipo atual. A proteção contra edição
## manual do arquivo permanece registrada para uma etapa futura.
extends Node

## Caminho local utilizado pelo Godot para armazenar o save do jogador.
const SAVE_PATH: String = "user://queen_survivors_save.json"

## Estado permanente atualmente carregado em memória.
var save_data: SaveData = null

## Configura o autoload para continuar processando em pausas,
## carrega o save e conecta os eventos necessários.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	load_or_create_save()
	_connect_events()

## Retorna o save atualmente carregado.
##
## Caso ainda não exista estado em memória, tenta carregá-lo ou criá-lo
## antes de retornar.
func get_save_data() -> SaveData:
	if save_data == null:
		load_or_create_save()

	return save_data

## Carrega o save existente em disco ou cria um novo save padrão.
##
## Caso exista arquivo mas seu conteúdo seja inválido, o fluxo cria
## um novo estado padrão para manter o jogo utilizável.
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

## Serializa o save atualmente carregado e grava o arquivo em disco.
##
## Retorna `true` quando a escrita termina com sucesso e `false`
## quando não há save carregado ou o arquivo não pode ser aberto.
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

## Aplica ao progresso permanente o resultado final de uma run concluída.
##
## Fluxo:
## 1. valida o payload recebido pelo evento `GameEvents.run_finished`;
## 2. garante que existe save em memória;
## 3. aplica XP, dinheiro, conclusão de mapa e recordes;
## 4. persiste os dados em disco;
## 5. emite sinais para interfaces e ferramentas técnicas.
func apply_run_result(result_payload: RunResultPayload) -> void:
	if result_payload == null:
		return

	if save_data == null:
		load_or_create_save()

	if save_data == null:
		return

	save_data.apply_run_result(result_payload)

	var saved_successfully: bool = save_to_disk()

	GameEvents.save_updated.emit(save_data)
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

## Reseta somente a progressão permanente atualmente suportada.
##
## A run em execução não é reiniciada automaticamente.
## Após o reset, emite `save_updated` para que ferramentas de debug
## atualizem os valores exibidos.
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

## Retorna uma visão técnica do save carregado para painéis de diagnóstico.
##
## Este método não deve ser usado como contrato permanente de interfaces
## finais do jogo; sua finalidade é apoiar ferramentas do protótipo.
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

## Conecta o SaveManager ao encerramento definitivo da run.
##
## O signal é emitido pelo RunController somente após vitória ou derrota
## estarem consolidadas em um `RunResultPayload`.
func _connect_events() -> void:
	if not GameEvents.run_finished.is_connected(_on_run_finished):
		GameEvents.run_finished.connect(_on_run_finished)

## Callback chamado quando uma run termina com resultado definitivo.
##
## Encaminha o payload para aplicação e persistência no save permanente.
func _on_run_finished(result_payload: RunResultPayload) -> void:
	apply_run_result(result_payload)

## Cria um save padrão em memória e tenta persistir imediatamente em disco.
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

## Lê o JSON armazenado em disco e o converte para um `SaveData`.
##
## Retorna `false` quando o arquivo não pode ser lido ou quando seu
## conteúdo não representa um dicionário JSON válido.
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
