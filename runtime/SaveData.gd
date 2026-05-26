## Modelo de dados persistentes do jogador.
##
## Representa o conteúdo serializado pelo SaveManager e mantém somente
## progresso permanente ou informações resumidas importantes:
## - XP total;
## - dinheiro acumulado;
## - mapas concluídos;
## - último resultado;
## - recordes básicos;
## - configurações persistentes;
## - estrutura futura de upgrades comprados.
extends Resource
class_name SaveData

## Versão atual do formato de save.
## Deve ser incrementada futuramente caso alterações exijam migração de dados.
var save_version: int = 1

## XP permanente acumulada ao final das runs.
##
## A mesma XP é utilizada durante a run para level-up e posteriormente
## adicionada à progressão permanente ao encerrar a partida.
var total_xp: int = 0

## Dinheiro permanente entregue ao final das runs.
var total_money: int = 0

## IDs dos mapas vencidos ao menos uma vez.
var completed_maps: Array[String] = []

## Resumo serializado da última run concluída.
##
## Mantém apenas a execução mais recente, evitando histórico detalhado infinito.
var last_run_summary: Dictionary = {}

## Recordes simples agregados por mapa.
##
## Esta estrutura registra estatísticas úteis sem armazenar cada run
## individualmente em histórico permanente.
var basic_records: Dictionary = {
	"best_survived_seconds_by_map": {},
	"best_level_by_map": {},
	"best_coins_by_map": {},
	"best_kills_by_map": {},
	"victories_by_map": {}
}

## Configurações simples persistidas no save.
##
## No protótipo atual, armazena o idioma previsto para carregamento futuro.
var settings: Dictionary = {
	"language": "pt_br"
}

## Define se o modo seguro está ativo.
var sfw_enabled: bool = true

## Define se a escolha inicial relacionada ao modo seguro já foi respondida.
var sfw_first_prompt_answered: bool = false

## Estrutura reservada para progressão comprada fora da run.
##
## A regra futura é salvar IDs, níveis e custos pagos, em vez de persistir
## apenas atributos finais já calculados.
var purchased_upgrades: Dictionary = {}

## Aplica ao progresso permanente os resultados de uma run finalizada.
##
## Regras atuais:
## - XP obtida na run é somada ao total permanente;
## - dinheiro final calculado pela run é somado ao total;
## - vitória marca mapa concluído e incrementa contador de vitórias;
## - o resumo mais recente substitui o resumo anterior;
## - recordes simples são atualizados quando superados.
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

## Reseta a progressão permanente controlada pelo protótipo.
##
## Mantém configurações pessoais e flags de modo seguro, removendo apenas:
## - XP;
## - dinheiro;
## - mapas concluídos;
## - último resultado;
## - recordes;
## - upgrades permanentes comprados.
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

## Converte o estado persistente para dicionário serializável em JSON.
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

## Reconstrói o estado persistente a partir de um dicionário lido do save.
##
## Utiliza valores padrão quando alguma chave ainda não existe, permitindo
## compatibilidade simples com saves gerados antes de novos campos.
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

## Marca um mapa como concluído, evitando IDs vazios ou repetidos.
func _mark_map_completed(map_id: String) -> void:
	if map_id.strip_edges() == "":
		return

	if completed_maps.has(map_id):
		return

	completed_maps.append(map_id)

## Atualiza os melhores recordes básicos alcançados em determinado mapa.
##
## Caso o payload não possua mapa válido, utiliza `unknown_map` apenas
## para não perder os dados estatísticos da execução.
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

## Incrementa a quantidade de vitórias registradas para um mapa válido.
func _increment_map_victory(map_id: String) -> void:
	if map_id.strip_edges() == "":
		return

	var victories: Dictionary = _get_record_dictionary("victories_by_map")
	var current_value: int = int(victories.get(map_id, 0))

	victories[map_id] = current_value + 1
	basic_records["victories_by_map"] = victories

## Atualiza um recorde inteiro somente quando o novo valor supera o anterior.
func _set_best_int_record(record_key: String, map_id: String, value: int) -> void:
	var record: Dictionary = _get_record_dictionary(record_key)
	var previous_value: int = int(record.get(map_id, 0))

	if value > previous_value:
		record[map_id] = value

	basic_records[record_key] = record

## Atualiza um recorde decimal somente quando o novo valor supera o anterior.
func _set_best_float_record(record_key: String, map_id: String, value: float) -> void:
	var record: Dictionary = _get_record_dictionary(record_key)
	var previous_value: float = float(record.get(map_id, 0.0))

	if value > previous_value:
		record[map_id] = value

	basic_records[record_key] = record

## Recupera de forma segura o dicionário interno correspondente a um recorde.
##
## Retorna dicionário vazio caso o campo esteja ausente ou corrompido.
func _get_record_dictionary(record_key: String) -> Dictionary:
	var record_variant: Variant = basic_records.get(record_key, {})

	if record_variant is Dictionary:
		return record_variant as Dictionary

	return {}

## Mescla recordes carregados com a estrutura mínima esperada pelo save atual.
##
## Assim, saves antigos ou incompletos sempre recebem todas as categorias
## necessárias sem perder categorias válidas previamente persistidas.
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

## Converte um valor para Dictionary quando possível.
##
## Evita erros de carregamento quando campos de save possuem tipo inesperado.
func _safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary

	return {}
