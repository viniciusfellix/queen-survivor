## Logger técnico centralizado para desenvolvimento, auditoria e QA.
##
## Responsabilidades:
## - registrar logs organizados por canais;
## - permitir habilitar/desabilitar canais específicos;
## - imprimir logs no console quando configurado;
## - manter um buffer interno de logs recentes para ferramentas técnicas;
## - evitar console poluído com logs de combate, spawn ou animação quando não forem necessários.
##
## Importante:
## Este logger é ferramenta de desenvolvimento.
## Ele não deve alterar gameplay, save ou regras da run.
extends Node

## Quantidade máxima de entradas mantidas no buffer interno.
##
## Quando o limite é ultrapassado, as entradas mais antigas são removidas.
const MAX_BUFFER_ENTRIES: int = 500

## Dicionário que define quais canais estão ativos.
##
## Chave: nome do canal.
## Valor: bool indicando se o canal imprime/captura logs.
var enabled_channels: Dictionary = {}

## Buffer em memória com as últimas entradas registradas.
##
## Útil para debug overlays, painéis técnicos ou exportações futuras.
var captured_entries: Array[Dictionary] = []

## Define se os logs devem ser impressos no console.
var print_to_console: bool = true

## Define se as entradas também devem ser armazenadas no buffer interno.
var capture_entries_in_memory: bool = true

## Inicializa os canais padrão e registra lifecycle do próprio logger.
func _ready() -> void:
	_configure_default_channels()
	log_lifecycle("DeveloperAuditLogger inicializado.", "DeveloperAuditLogger")

## Configura quais canais começam ligados ou desligados.
##
## Por padrão, apenas lifecycle fica ativo.
## Canais verbosos como COMBAT, SPAWN, ANIMATION e UPGRADE começam desligados
## para evitar excesso de informações durante testes normais.
func _configure_default_channels() -> void:
	enabled_channels = {
		DeveloperLogChannels.LIFECYCLE: true,
		DeveloperLogChannels.SCENE: false,
		DeveloperLogChannels.SPAWN: false,
		DeveloperLogChannels.COMBAT: false,
		DeveloperLogChannels.ANIMATION: false,
		DeveloperLogChannels.UPGRADE: false,
		DeveloperLogChannels.SAVE: false,
		DeveloperLogChannels.UI: false,
		DeveloperLogChannels.SIGNAL: false,
		DeveloperLogChannels.AUDIT: false
	}

## Registra uma entrada de log em um canal específico.
##
## Parâmetros:
## - channel: canal técnico do log;
## - message: mensagem principal;
## - source: sistema/script de origem;
## - metadata: dados extras para investigação.
##
## Se o canal estiver desligado, nada acontece.
func write_entry(
	channel: String,
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	if not is_channel_enabled(channel):
		return

	var source_prefix: String = ""

	if source.strip_edges() != "":
		source_prefix = "[%s] " % source

	var formatted_message: String = "[DEV][%s] %s%s" % [
		channel,
		source_prefix,
		message
	]

	if print_to_console:
		print(formatted_message)

	if not capture_entries_in_memory:
		return

	var entry: Dictionary = {
		"channel": channel,
		"source": source,
		"message": message,
		"metadata": metadata.duplicate(true),
		"ticks_msec": Time.get_ticks_msec()
	}

	captured_entries.append(entry)

	## Mantém o buffer dentro do limite configurado.
	while captured_entries.size() > MAX_BUFFER_ENTRIES:
		captured_entries.pop_front()

## Atalho para logar eventos de lifecycle/boot/inicialização.
func log_lifecycle(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.LIFECYCLE, message, source, metadata)

## Atalho para logar montagem, carregamento e troca de cenas.
func log_scene(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SCENE, message, source, metadata)

## Atalho para logar spawn, criação de inimigos e drops.
func log_spawn(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SPAWN, message, source, metadata)

## Atalho para logar dano, ataques, hitbox/hurtbox e combate.
func log_combat(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.COMBAT, message, source, metadata)

## Atalho para logar animações e controladores visuais.
func log_animation(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.ANIMATION, message, source, metadata)

## Atalho para logar aplicação de upgrades e mudanças temporárias da run.
func log_upgrade(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UPGRADE, message, source, metadata)

## Atalho para logar carregamento, gravação e reset de save.
func log_save(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SAVE, message, source, metadata)

## Atalho para logar comportamento de HUD, painéis e feedbacks.
func log_ui(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UI, message, source, metadata)

## Atalho para logar emissão ou consumo de signals quando necessário.
func log_signal(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SIGNAL, message, source, metadata)

## Atalho para logar auditorias, limpezas, validações e alterações técnicas.
func log_audit(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.AUDIT, message, source, metadata)

## Habilita ou desabilita um canal de log.
##
## Se o canal não existir em DeveloperLogChannels, emite warning e não altera.
func set_channel_enabled(channel: String, should_enable: bool) -> void:
	if not DeveloperLogChannels.get_all_channels().has(channel):
		push_warning("[DeveloperAuditLogger] Canal desconhecido: %s" % channel)
		return

	enabled_channels[channel] = should_enable

	log_audit(
		"Canal atualizado: %s=%s" % [channel, str(should_enable)],
		"DeveloperAuditLogger"
	)

## Retorna se determinado canal está habilitado.
func is_channel_enabled(channel: String) -> bool:
	return bool(enabled_channels.get(channel, false))

## Limpa o buffer interno de logs capturados.
##
## Não afeta console nem configuração dos canais.
func clear_captured_entries() -> void:
	captured_entries.clear()
	log_audit("Buffer interno de logs limpo.", "DeveloperAuditLogger")

## Retorna uma cópia do buffer interno de logs.
##
## A cópia evita que sistemas externos alterem diretamente o array original.
func get_captured_entries() -> Array[Dictionary]:
	return captured_entries.duplicate(true)

## Retorna um texto compacto com os canais atualmente habilitados.
##
## Útil para painéis técnicos, debug overlay ou relatório de QA.
func get_enabled_channels_summary() -> String:
	var enabled_names: Array[String] = []

	for channel: String in DeveloperLogChannels.get_all_channels():
		if is_channel_enabled(channel):
			enabled_names.append(channel)

	return ", ".join(enabled_names)
