extends "res://visual/spine/SpineVisualControllerBase.gd"

@export_group("Animations")

@export var idle_animation_name: String = "Idle1_Pose2"

@export var run_animation_name: String = "Run1_Pose3"

@export var dash_animation_name: String = "Dash1_Pose3"

@export var death_animation_name: String = "Die_Pose1"

@export var dash_side_animation_name: String = "Dash1_Pose3"
@export var dash_up_animation_name: String = ""
@export var dash_down_animation_name: String = ""
@export_range(0.0, 1.0, 0.05) var dash_vertical_threshold: float = 0.55

@export_group("Blink Overlay")

@export var blink_enabled: bool = true

@export var blink_track_index: int = 1

@export var blink_interval_min_seconds: float = 1.0

@export var blink_interval_max_seconds: float = 7.0

@export var idle_blink_animation_name: String = "Blink_Idle_Pose2"

@export var run_blink_animation_name: String = ""

@export var dash_blink_animation_name: String = ""

@export var allow_blink_while_dashing: bool = false

@export var blink_animation_duration_seconds: float = 0.22

@export var allow_blink_while_running: bool = true

@export_group("Damage Flash")

@export var damage_flash_color: Color = Color(1.0, 0.25, 0.25, 1.0)

@export var damage_flash_duration: float = 0.12

var damage_flash_tween: Tween = null

var default_modulate: Color = Color.WHITE

var is_blink_playing: bool = false

var blink_schedule_token: int = 0

var last_gameplay_state: String = GameplayStateTypes.IDLE

func _ready() -> void:
	default_modulate = modulate
	super._ready()
	_schedule_next_blink()

func _get_visual_log_name() -> String:
	return "GaiaVisualController"

func _play_initial_animation() -> void:
	play_idle()

func apply_runtime_state(runtime_state: PlayerRuntimeState) -> void:
	if runtime_state == null:
		return

	_apply_horizontal_facing(runtime_state.facing_direction)

	var previous_gameplay_state: String = last_gameplay_state
	var gameplay_state: String = runtime_state.current_gameplay_state
	last_gameplay_state = gameplay_state

	if previous_gameplay_state != gameplay_state:
		if not _state_supports_blink_overlay(gameplay_state):
			_clear_blink_overlay_track()

	if gameplay_state == GameplayStateTypes.DEAD:
		_cancel_blink()
		runtime_state.current_visual_state = GameplayStateTypes.DEAD
		play_death()
		return

	runtime_state.current_visual_state = gameplay_state

	match gameplay_state:
		GameplayStateTypes.IDLE:
			play_idle()

		GameplayStateTypes.MOVING:
			play_run()

		GameplayStateTypes.DASHING:
			play_dash(
				runtime_state.dash_direction,
				runtime_state.dash_animation_time_scale
			)

		_:
			play_idle()

func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		GameplayStateTypes.IDLE
	)

func play_run() -> void:
	_play_animation_if_changed(
		run_animation_name,
		true,
		GameplayStateTypes.MOVING
	)

func play_dash(
	dash_direction: Vector2 = Vector2.ZERO,
	time_scale: float = 1.0
) -> void:
	var animation_name: String = _get_dash_animation_name(dash_direction)

	_play_animation_if_changed(
		animation_name,
		false,
		GameplayStateTypes.DASHING,
		time_scale
	)

func play_death() -> void:
	_play_animation_if_changed(
		death_animation_name,
		false,
		GameplayStateTypes.DEAD
	)

func play_damage_flash() -> void:
	if damage_flash_tween != null:
		damage_flash_tween.kill()
		damage_flash_tween = null

	modulate = damage_flash_color

	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(
		self,
		"modulate",
		default_modulate,
		damage_flash_duration
	)

	damage_flash_tween.finished.connect(func() -> void:
		damage_flash_tween = null
	)

func _schedule_next_blink() -> void:
	blink_schedule_token += 1

	if not blink_enabled:
		return

	if not is_inside_tree():
		return

	var safe_min_seconds: float = max(0.1, blink_interval_min_seconds)
	var safe_max_seconds: float = max(safe_min_seconds, blink_interval_max_seconds)
	var wait_seconds: float = randf_range(safe_min_seconds, safe_max_seconds)
	var token: int = blink_schedule_token

	var timer: SceneTreeTimer = get_tree().create_timer(wait_seconds)

	timer.timeout.connect(func() -> void:
		if token != blink_schedule_token:
			return

		_try_play_scheduled_blink()
	)

func _try_play_scheduled_blink() -> void:
	if not blink_enabled:
		return

	if is_blink_playing:
		_schedule_next_blink()
		return

	var blink_animation_name: String = _get_blink_animation_for_current_state()

	if blink_animation_name.strip_edges() == "":
		_schedule_next_blink()
		return

	_play_blink_overlay_animation(blink_animation_name)

func _state_supports_blink_overlay(gameplay_state: String) -> bool:
	match gameplay_state:
		GameplayStateTypes.IDLE:
			return idle_blink_animation_name.strip_edges() != ""

		GameplayStateTypes.MOVING:
			return (
				allow_blink_while_running
				and run_blink_animation_name.strip_edges() != ""
			)

		GameplayStateTypes.DASHING:
			return (
				allow_blink_while_dashing
				and dash_blink_animation_name.strip_edges() != ""
			)

		_:
			return false

func _clear_blink_overlay_track() -> void:
	is_blink_playing = false

	var safe_track_index: int = max(1, blink_track_index)
	_clear_animation_track(safe_track_index)

func _get_blink_animation_for_current_state() -> String:
	match last_gameplay_state:
		GameplayStateTypes.IDLE:
			return idle_blink_animation_name

		GameplayStateTypes.MOVING:
			if not allow_blink_while_running:
				return ""

			return run_blink_animation_name

		GameplayStateTypes.DASHING:
			if not allow_blink_while_dashing:
				return ""

			return dash_blink_animation_name

		_:
			return ""

func _play_blink_overlay_animation(blink_animation_name: String) -> void:
	if blink_animation_name.strip_edges() == "":
		_schedule_next_blink()
		return

	var safe_track_index: int = max(1, blink_track_index)

	var played_successfully: bool = _play_animation_on_track(
		blink_animation_name,
		false,
		safe_track_index,
		false
	)

	if not played_successfully:
		_schedule_next_blink()
		return

	is_blink_playing = true

	var token: int = blink_schedule_token
	var duration_seconds: float = max(0.01, blink_animation_duration_seconds)
	var timer: SceneTreeTimer = get_tree().create_timer(duration_seconds)

	timer.timeout.connect(func() -> void:
		if token != blink_schedule_token:
			return

		_finish_blink_overlay()
	)

func _finish_blink_overlay() -> void:
	is_blink_playing = false

	var safe_track_index: int = max(1, blink_track_index)
	_clear_animation_track(safe_track_index)

	_schedule_next_blink()

func _cancel_blink() -> void:
	blink_schedule_token += 1
	_clear_blink_overlay_track()

func _get_dash_animation_name(dash_direction: Vector2) -> String:
	var safe_dash_direction: Vector2 = dash_direction

	if safe_dash_direction.length() <= 0.001:
		return _get_fallback_dash_animation_name()

	safe_dash_direction = safe_dash_direction.normalized()

	if (
		abs(safe_dash_direction.y) >= dash_vertical_threshold
		and abs(safe_dash_direction.y) > abs(safe_dash_direction.x)
	):
		if safe_dash_direction.y < 0.0:
			if dash_up_animation_name.strip_edges() != "":
				return dash_up_animation_name
		else:
			if dash_down_animation_name.strip_edges() != "":
				return dash_down_animation_name

	return _get_fallback_dash_animation_name()

func _get_fallback_dash_animation_name() -> String:
	if dash_side_animation_name.strip_edges() != "":
		return dash_side_animation_name

	return dash_animation_name
