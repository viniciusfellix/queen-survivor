extends Node
class_name SpineAnimationAdapterBase

@export_group("Spine")
@export var spine_sprite_path: NodePath

@export_group("Diagnostics")
@export var log_ready_status: bool = false
@export var log_animation_changes: bool = false
@onready var spine_sprite: Node = _resolve_spine_sprite()

var current_animation_name: String = ""
var current_animation_by_track: Dictionary = {}
var is_spine_ready: bool = false
var current_time_scale_by_track: Dictionary = {}

func _ready() -> void:
	is_spine_ready = spine_sprite != null

	if not is_spine_ready:
		push_warning("[%s] SpineSprite não configurado ou não encontrado." % _get_adapter_log_name())
		return

	if log_ready_status:
		DeveloperAuditLogger.log_animation(
			"SpineSprite encontrado: %s" % spine_sprite.name,
			_get_adapter_log_name(),
			{
				"spine_sprite_name": spine_sprite.name
			}
		)

func play_animation(
	animation_name: String,
	loop: bool = true,
	time_scale: float = 1.0
) -> bool:
	return play_animation_on_track(animation_name, loop, 0, true, time_scale)
	
func play_animation_on_track(
	animation_name: String,
	loop: bool = true,
	track_index: int = 0,
	updates_base_animation: bool = false,
	time_scale: float = 1.0
) -> bool:
	if animation_name.strip_edges() == "":
		return false

	var safe_track_index: int = max(0, track_index)
	var safe_time_scale: float = max(0.01, time_scale)

	if not is_spine_ready:
		push_warning("[%s] Não foi possível tocar animação; SpineSprite ausente: %s" % [
			_get_adapter_log_name(),
			animation_name
		])
		return false

	var current_track_animation: String = str(
		current_animation_by_track.get(safe_track_index, "")
	)

	var current_track_time_scale: float = float(
		current_time_scale_by_track.get(safe_track_index, 1.0)
	)

	if (
		current_track_animation == animation_name
		and is_equal_approx(current_track_time_scale, safe_time_scale)
	):
		return true

	var played_successfully: bool = _try_play_with_animation_state(
		animation_name,
		loop,
		safe_track_index,
		safe_time_scale
	)

	if not played_successfully:
		push_warning("[%s] Falha ao tocar animação pela API Spine: %s | track=%s" % [
			_get_adapter_log_name(),
			animation_name,
			str(safe_track_index)
		])
		return false

	current_animation_by_track[safe_track_index] = animation_name
	current_time_scale_by_track[safe_track_index] = safe_time_scale

	if updates_base_animation or safe_track_index == 0:
		current_animation_name = animation_name

		if _should_publish_animation_changed():
			GameEvents.spine_animation_changed.emit(animation_name)

	if log_animation_changes:
		DeveloperAuditLogger.log_animation(
			"Animação executada: %s | loop=%s | track=%s | updates_base=%s | time_scale=%s" % [
				animation_name,
				str(loop),
				str(safe_track_index),
				str(updates_base_animation),
				str(safe_time_scale)
			],
			_get_adapter_log_name(),
			{
				"animation_name": animation_name,
				"loop": loop,
				"track_index": safe_track_index,
				"updates_base_animation": updates_base_animation,
				"time_scale": safe_time_scale
			}
		)

	return true
	
func clear_animation_track(track_index: int) -> bool:
	var safe_track_index: int = max(0, track_index)

	current_animation_by_track.erase(safe_track_index)
	current_time_scale_by_track.erase(safe_track_index)

	if safe_track_index == 0:
		current_animation_name = ""

	if not is_spine_ready:
		return false

	var cleared_successfully: bool = _try_clear_animation_track(safe_track_index)

	if log_animation_changes:
		DeveloperAuditLogger.log_animation(
			"Track limpa: track=%s success=%s" % [
				str(safe_track_index),
				str(cleared_successfully)
			],
			_get_adapter_log_name(),
			{
				"track_index": safe_track_index,
				"success": cleared_successfully
			}
		)

	return cleared_successfully

## Limpa tracks e cache interno para reuso pooled seguro do visual dono.
func reset_adapter_state() -> void:
	var tracked_indices: Array[int] = []

	for track_key: Variant in current_animation_by_track.keys():
		if track_key is int:
			tracked_indices.append(int(track_key))

	for track_key: Variant in current_time_scale_by_track.keys():
		if track_key is int and not tracked_indices.has(int(track_key)):
			tracked_indices.append(int(track_key))

	if tracked_indices.is_empty():
		tracked_indices.append(0)

	for track_index: int in tracked_indices:
		clear_animation_track(track_index)

	current_animation_name = ""
	current_animation_by_track.clear()
	current_time_scale_by_track.clear()

func get_current_animation_name() -> String:
	return current_animation_name

func is_ready_for_animation() -> bool:
	return is_spine_ready

func _should_publish_animation_changed() -> bool:
	return false

func _get_adapter_log_name() -> String:
	return name

func _resolve_spine_sprite() -> Node:
	if spine_sprite_path != NodePath():
		var configured_node: Node = get_node_or_null(spine_sprite_path)

		if configured_node != null:
			return configured_node

	var sibling: Node = get_node_or_null("../SpineSprite")

	if sibling != null and sibling.get_class() == "SpineSprite":
		return sibling

	var parent_node: Node = get_parent()

	if parent_node == null:
		return null

	return _find_first_spine_sprite(parent_node)

func _find_first_spine_sprite(root: Node) -> Node:
	if root == null:
		return null

	if root.get_class() == "SpineSprite":
		return root

	for child: Node in root.get_children():
		var found_node: Node = _find_first_spine_sprite(child)

		if found_node != null:
			return found_node

	return null

func _try_play_with_animation_state(
	animation_name: String,
	loop: bool,
	track_index: int,
	time_scale: float = 1.0
) -> bool:
	if spine_sprite == null:
		return false

	if not spine_sprite.has_method("get_animation_state"):
		return false

	var animation_state_variant: Variant = spine_sprite.call("get_animation_state")

	if animation_state_variant == null:
		return false

	if not animation_state_variant is Object:
		return false

	var animation_state: Object = animation_state_variant as Object

	if not animation_state.has_method("set_animation"):
		return false

	var track_entry_variant: Variant = animation_state.call(
		"set_animation",
		animation_name,
		loop,
		track_index
	)

	_try_apply_time_scale_to_track_entry(track_entry_variant, time_scale)

	return true

func _try_clear_animation_track(track_index: int) -> bool:
	if spine_sprite == null:
		return false

	if not spine_sprite.has_method("get_animation_state"):
		return false

	var animation_state_variant: Variant = spine_sprite.call("get_animation_state")

	if animation_state_variant == null:
		return false

	if not animation_state_variant is Object:
		return false

	var animation_state: Object = animation_state_variant as Object

	if animation_state.has_method("clear_track"):
		animation_state.call("clear_track", track_index)
		return true

	if animation_state.has_method("set_empty_animation"):
		animation_state.call("set_empty_animation", track_index, 0.05)
		return true

	return false

func _try_apply_time_scale_to_track_entry(
	track_entry_variant: Variant,
	time_scale: float
) -> void:
	if track_entry_variant == null:
		return

	if not track_entry_variant is Object:
		return

	var track_entry: Object = track_entry_variant as Object
	var safe_time_scale: float = max(0.01, time_scale)

	if track_entry.has_method("set_time_scale"):
		track_entry.call("set_time_scale", safe_time_scale)
		return

	if track_entry.has_method("setTimeScale"):
		track_entry.call("setTimeScale", safe_time_scale)
		return

	for property_info: Dictionary in track_entry.get_property_list():
		var property_name: String = str(property_info.get("name", ""))

		if property_name == "time_scale":
			track_entry.set("time_scale", safe_time_scale)
			return

		if property_name == "timeScale":
			track_entry.set("timeScale", safe_time_scale)
			return
