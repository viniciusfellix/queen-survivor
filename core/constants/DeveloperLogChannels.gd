extends RefCounted
class_name DeveloperLogChannels

const LIFECYCLE: String = "LIFECYCLE"

const SCENE: String = "SCENE"

const SPAWN: String = "SPAWN"

const COMBAT: String = "COMBAT"

const ANIMATION: String = "ANIMATION"

const UPGRADE: String = "UPGRADE"

const SAVE: String = "SAVE"

const UI: String = "UI"

const SIGNAL: String = "SIGNAL"

const AUDIT: String = "AUDIT"

static func get_all_channels() -> Array[String]:
	return [
		LIFECYCLE,
		SCENE,
		SPAWN,
		COMBAT,
		ANIMATION,
		UPGRADE,
		SAVE,
		UI,
		SIGNAL,
		AUDIT,
	]
