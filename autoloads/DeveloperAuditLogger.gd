## Logger técnico global do projeto.
##
## Centraliza mensagens de diagnóstico por domínio, permitindo:
## - ativar somente os canais necessários para cada rodada de testes;
## - imprimir mensagens padronizadas no console;
## - manter um buffer interno recente para futuras ferramentas de auditoria.
##
## Este logger não substitui warnings ou erros reais:
## configurações inválidas ainda devem utilizar push_warning() ou push_error().
extends Node

## Quantidade máxima de entradas mantidas no buffer interno.
## Quando o limite é ultrapassado, os registros mais antigos são removidos.
const MAX_BUFFER_ENTRIES: int = 500

## Dicionário com o estado ativo/inativo de cada canal técnico.
var enabled_channels: Dictionary = {}

## Buffer em memória com as entradas capturadas durante a execução atual.
var captured_entries: Array[Dictionary] = []

## Define se mensagens de canais ativos devem ser impressas no console.
var print_to_console: bool = true

## Define se mensagens de canais ativos também devem ser armazenadas em memória.
var capture_entries_in_memory: bool = true

## Inicializa os canais padrão e registra que o logger está disponível.
func _ready() -> void:
	_configure_default_channels()
	log_lifecycle("DeveloperAuditLogger inicializado.", "DeveloperAuditLogger")

## Define os canais que devem permanecer ativos durante execução comum.
##
## Canais detalhados, como SPAWN, COMBAT, ANIMATION, UPGRADE e UI,
## ficam desligados por padrão e são ativados apenas durante testes específicos.
func _configure_default_channels() -> void:
	enabled_channels = {
		DeveloperLogChannels.LIFECYCLE: true,
		DeveloperLogChannels.SCENE: true,
		DeveloperLogChannels.SPAWN: true,
		DeveloperLogChannels.COMBAT: true,
		DeveloperLogChannels.ANIMATION: true,
		DeveloperLogChannels.UPGRADE: false,
		DeveloperLogChannels.SAVE: true,
		DeveloperLogChannels.UI: false,
		DeveloperLogChannels.SIGNAL: false,
		DeveloperLogChannels.AUDIT: false
	}

## Registra uma entrada em um canal técnico.
##
## A mensagem só é processada quando o canal informado estiver ativo.
## `source` identifica o script ou sistema de origem.
## `metadata` mantém valores estruturados úteis para inspeção futura.
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

	while captured_entries.size() > MAX_BUFFER_ENTRIES:
		captured_entries.pop_front()

## Registra evento relacionado ao ciclo de vida geral da aplicação ou da run.
func log_lifecycle(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.LIFECYCLE, message, source, metadata)

## Registra carregamento, instanciação ou configuração estrutural de cenas.
func log_scene(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SCENE, message, source, metadata)

## Registra geração de inimigos, drops, waves ou coleta de moedas.
func log_spawn(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SPAWN, message, source, metadata)

## Registra interações de combate, dano e mortes.
func log_combat(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.COMBAT, message, source, metadata)

## Registra mudanças de animação ou estado visual.
func log_animation(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.ANIMATION, message, source, metadata)

## Registra abertura de level-up e aplicação de upgrades durante a run.
func log_upgrade(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UPGRADE, message, source, metadata)

## Registra leitura, escrita, reset ou atualização do progresso permanente.
func log_save(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SAVE, message, source, metadata)

## Registra eventos relacionados a HUD, painéis e feedbacks visuais.
func log_ui(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UI, message, source, metadata)

## Registra diagnósticos específicos de comunicação por signals.
func log_signal(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SIGNAL, message, source, metadata)

## Registra ações manuais de ferramenta técnica ou auditoria.
func log_audit(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.AUDIT, message, source, metadata)

## Ativa ou desativa um canal técnico em runtime.
##
## Caso o canal não exista no catálogo oficial, emite warning e ignora a alteração.
## A própria alteração é registrada no canal AUDIT quando ele estiver ativo.
func set_channel_enabled(channel: String, should_enable: bool) -> void:
	if not DeveloperLogChannels.get_all_channels().has(channel):
		push_warning("[DeveloperAuditLogger] Canal desconhecido: %s" % channel)
		return

	enabled_channels[channel] = should_enable

	log_audit(
		"Canal atualizado: %s=%s" % [channel, str(should_enable)],
		"DeveloperAuditLogger"
	)

## Informa se determinado canal técnico está ativo no momento.
func is_channel_enabled(channel: String) -> bool:
	return bool(enabled_channels.get(channel, false))

## Remove todas as entradas atualmente mantidas no buffer de auditoria.
func clear_captured_entries() -> void:
	captured_entries.clear()
	log_audit("Buffer interno de logs limpo.", "DeveloperAuditLogger")

## Retorna uma cópia profunda das entradas capturadas na execução atual.
##
## A cópia impede que consumidores externos alterem o buffer interno do logger.
func get_captured_entries() -> Array[Dictionary]:
	return captured_entries.duplicate(true)

## Retorna os nomes dos canais atualmente habilitados em formato legível.
func get_enabled_channels_summary() -> String:
	var enabled_names: Array[String] = []

	for channel: String in DeveloperLogChannels.get_all_channels():
		if is_channel_enabled(channel):
			enabled_names.append(channel)

	return ", ".join(enabled_names)
