extends Node

const MAX_BUFFER_ENTRIES: int = 500

var enabled_channels: Dictionary = {}
var captured_entries: Array[Dictionary] = []

var print_to_console: bool = true
var capture_entries_in_memory: bool = true

func _ready() -> void:
	_configure_default_channels()
	log_lifecycle("DeveloperAuditLogger inicializado.", "DeveloperAuditLogger")

func _configure_default_channels() -> void:
	enabled_channels = {
		DeveloperLogChannels.LIFECYCLE: true,
		DeveloperLogChannels.SCENE: true,
		DeveloperLogChannels.SPAWN: false,
		DeveloperLogChannels.COMBAT: true,
		DeveloperLogChannels.ANIMATION: false,
		DeveloperLogChannels.UPGRADE: false,
		DeveloperLogChannels.SAVE: true,
		DeveloperLogChannels.UI: false,
		DeveloperLogChannels.SIGNAL: false,
		DeveloperLogChannels.AUDIT: true,
		DeveloperLogChannels.LEGACY: false
	}

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

func log_lifecycle(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.LIFECYCLE, message, source, metadata)

func log_scene(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SCENE, message, source, metadata)

func log_spawn(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SPAWN, message, source, metadata)

func log_combat(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.COMBAT, message, source, metadata)

func log_animation(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.ANIMATION, message, source, metadata)

func log_upgrade(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UPGRADE, message, source, metadata)

func log_save(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SAVE, message, source, metadata)

func log_ui(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.UI, message, source, metadata)

func log_signal(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.SIGNAL, message, source, metadata)

func log_audit(
	message: String,
	source: String = "",
	metadata: Dictionary = {}
) -> void:
	write_entry(DeveloperLogChannels.AUDIT, message, source, metadata)

func log_legacy(message: String, source: String = "") -> void:
	write_entry(DeveloperLogChannels.LEGACY, message, source)

func set_channel_enabled(channel: String, should_enable: bool) -> void:
	if not DeveloperLogChannels.get_all_channels().has(channel):
		push_warning("[DeveloperAuditLogger] Canal desconhecido: %s" % channel)
		return

	enabled_channels[channel] = should_enable

	log_audit(
		"Canal atualizado: %s=%s" % [channel, str(should_enable)],
		"DeveloperAuditLogger"
	)

func is_channel_enabled(channel: String) -> bool:
	return bool(enabled_channels.get(channel, false))

func clear_captured_entries() -> void:
	captured_entries.clear()
	log_audit("Buffer interno de logs limpo.", "DeveloperAuditLogger")

func get_captured_entries() -> Array[Dictionary]:
	return captured_entries.duplicate(true)

func get_enabled_channels_summary() -> String:
	var enabled_names: Array[String] = []

	for channel: String in DeveloperLogChannels.get_all_channels():
		if is_channel_enabled(channel):
			enabled_names.append(channel)

	return ", ".join(enabled_names)
