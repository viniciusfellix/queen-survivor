extends "res://visual/spine/SpineVisualControllerBase.gd"

@export_group("Animations")

@export var idle_animation_name: String = "Idle"

@export var run_animation_name: String = "Run"

@export var walk_animation_name: String = "Run"

@export var death_animation_name: String = "Die"

@export_group("Behaviour")

@export var use_walk_when_run_missing: bool = true

@export var flip_by_movement_direction: bool = true

@export_group("Damage Flash")

@export_range(1.0, 8.0, 0.1) var damage_flash_brightness: float = 4.0

@export var damage_flash_hold_seconds: float = 0.035

@export var damage_flash_duration: float = 0.12

var damage_flash_tween: Tween = null
var default_modulate: Color = Color.WHITE

func _ready() -> void:
	default_modulate = modulate
	super._ready()

func _get_visual_log_name() -> String:
	return "GoblinWarriorVisualController"

func _play_initial_animation() -> void:
	play_idle()

func apply_enemy_runtime_state(
	is_moving: bool,
	movement_direction: Vector2,
	is_alive: bool = true
) -> void:
	if not is_alive:
		play_death()
		return

	_apply_horizontal_facing(
		movement_direction,
		flip_by_movement_direction
	)

	if is_moving:
		play_run()
	else:
		play_idle()

func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		"idle"
	)

func play_run() -> void:
	var selected_animation: String = run_animation_name

	if selected_animation.strip_edges() == "" and use_walk_when_run_missing:
		selected_animation = walk_animation_name

	_play_animation_if_changed(
		selected_animation,
		true,
		"run"
	)

func play_death() -> void:
	_play_animation_if_changed(
		death_animation_name,
		false,
		"death"
	)

func play_damage_flash() -> void:
	if damage_flash_tween != null:
		damage_flash_tween.kill()
		damage_flash_tween = null

	var safe_brightness: float = max(1.0, damage_flash_brightness)
	var flash_modulate: Color = Color(
		safe_brightness,
		safe_brightness,
		safe_brightness,
		default_modulate.a
	)

	modulate = flash_modulate

	damage_flash_tween = create_tween()
	damage_flash_tween.set_trans(Tween.TRANS_QUAD)
	damage_flash_tween.set_ease(Tween.EASE_OUT)

	if damage_flash_hold_seconds > 0.0:
		damage_flash_tween.tween_interval(damage_flash_hold_seconds)

	damage_flash_tween.tween_property(
		self,
		"modulate",
		default_modulate,
		max(0.01, damage_flash_duration)
	)

	damage_flash_tween.finished.connect(func() -> void:
		damage_flash_tween = null
	)

	DeveloperAuditLogger.log_animation(
		"Flash de dano executado: brightness=%s hold=%s duration=%s" % [
			str(safe_brightness),
			str(damage_flash_hold_seconds),
			str(damage_flash_duration)
		],
		"GoblinWarriorVisualController",
		{
			"brightness": safe_brightness,
			"hold_seconds": damage_flash_hold_seconds,
			"duration_seconds": damage_flash_duration
		}
	)
