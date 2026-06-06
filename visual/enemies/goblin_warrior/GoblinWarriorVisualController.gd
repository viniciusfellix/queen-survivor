## Controller visual específico do Goblin Warrior.
##
## Responsabilidades:
## - escolher animações idle/run/death;
## - aplicar flip horizontal baseado na direção visual;
## - tocar animação correta conforme estado runtime;
## - executar flash visual quando recebe dano.
##
## Importante:
## Este script não decide movimento, dano, morte ou IA.
## Ele apenas representa visualmente o estado calculado por EnemyBase.
extends "res://visual/spine/SpineVisualControllerBase.gd"

@export_group("Animations")

## Nome da animação idle.
@export var idle_animation_name: String = "Idle"

## Nome da animação de corrida.
@export var run_animation_name: String = "Run"

## Nome de fallback para caminhada, se run não existir.
@export var walk_animation_name: String = "Run"

## Nome da animação de morte.
@export var death_animation_name: String = "Die"

@export_group("Behaviour")

## Usa walk_animation_name caso run_animation_name esteja vazio.
@export var use_walk_when_run_missing: bool = true

## Aplica flip horizontal pela direção de movimento visual.
@export var flip_by_movement_direction: bool = true

@export_group("Damage Flash")

## Intensidade do flash claro ao receber dano.
@export_range(1.0, 8.0, 0.1) var damage_flash_brightness: float = 4.0

## Tempo segurando o brilho máximo.
@export var damage_flash_hold_seconds: float = 0.035

## Tempo de retorno ao modulate padrão.
@export var damage_flash_duration: float = 0.12

## Tween atual do flash.
var damage_flash_tween: Tween = null

## Cor/modulate original do visual.
var default_modulate: Color = Color.WHITE

## Guarda modulate original e inicializa base.
func _ready() -> void:
	default_modulate = modulate
	super._ready()

## Nome usado em logs técnicos.
func _get_visual_log_name() -> String:
	return "GoblinWarriorVisualController"

## Animação inicial.
func _play_initial_animation() -> void:
	play_idle()

## Aplica estado visual recebido do EnemyBase.
##
## `movement_direction` deve representar intenção visual,
## não necessariamente a velocidade física final.
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

## Toca idle.
func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		"idle"
	)

## Toca run ou fallback de walk.
func play_run() -> void:
	var selected_animation: String = run_animation_name

	if selected_animation.strip_edges() == "" and use_walk_when_run_missing:
		selected_animation = walk_animation_name

	_play_animation_if_changed(
		selected_animation,
		true,
		"run"
	)

## Toca morte sem loop.
func play_death() -> void:
	_play_animation_if_changed(
		death_animation_name,
		false,
		"death"
	)

## Executa flash claro de dano.
##
## O efeito é puramente visual e não altera gameplay.
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
