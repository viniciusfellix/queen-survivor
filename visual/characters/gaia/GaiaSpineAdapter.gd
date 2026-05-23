extends "res://visual/spine/SpineAnimationAdapterBase.gd"

func _should_publish_animation_changed() -> bool:
	return true

func _get_adapter_log_name() -> String:
	return "GaiaSpineAdapter"
