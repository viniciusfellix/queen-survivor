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

## Sequencia configuravel do flash ao receber dano.
@export var damage_flash_colors: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0, 1.0)
]

@export var damage_flash_step_seconds: float = 0.06

@export var restore_default_between_flash_colors: bool = true

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

## Executa flash claro em sequencia.
##
## O efeito é puramente visual e não altera gameplay.
func play_damage_flash() -> void:
	_stop_damage_flash_tween()

	var flash_sequence: Array[Color] = _build_damage_flash_sequence()

	if flash_sequence.is_empty():
		modulate = default_modulate
		return

	modulate = flash_sequence[0]

	damage_flash_tween = create_tween()
	damage_flash_tween.set_trans(Tween.TRANS_QUAD)
	damage_flash_tween.set_ease(Tween.EASE_OUT)

	for sequence_index: int in range(1, flash_sequence.size()):
		damage_flash_tween.tween_property(
			self,
			"modulate",
			flash_sequence[sequence_index],
			max(0.01, damage_flash_step_seconds)
		)

	damage_flash_tween.finished.connect(func() -> void:
		modulate = default_modulate
		damage_flash_tween = null
	)

	DeveloperAuditLogger.log_animation(
		"Flash de dano executado: steps=%s step_seconds=%s restore_between=%s" % [
			str(flash_sequence.size()),
			str(damage_flash_step_seconds),
			str(restore_default_between_flash_colors)
		],
		"GoblinWarriorVisualController",
		{
			"steps": flash_sequence.size(),
			"step_seconds": damage_flash_step_seconds,
			"restore_default_between_flash_colors": restore_default_between_flash_colors
		}
	)

## Reseta estado visual para reuso pooled seguro antes do proximo spawn.
func reset_visual_state() -> void:
	_stop_damage_flash_tween()
	modulate = default_modulate
	visible = true
	current_animation_name = ""
	current_visual_state = ""
	current_animation_time_scale = 1.0
	scale = Vector2(abs(scale.x), abs(scale.y))

	if spine_adapter != null and spine_adapter.has_method("reset_adapter_state"):
		spine_adapter.call("reset_adapter_state")

## Coloca o visual em estado neutro ao sair do pool ativo.
func deactivate_for_pool() -> void:
	_stop_damage_flash_tween()
	modulate = default_modulate
	current_animation_name = ""
	current_visual_state = ""
	current_animation_time_scale = 1.0
	scale = Vector2(abs(scale.x), abs(scale.y))

	if spine_adapter != null and spine_adapter.has_method("reset_adapter_state"):
		spine_adapter.call("reset_adapter_state")

## Mata tween de flash para evitar reaproveitar brilho antigo.
func _stop_damage_flash_tween() -> void:
	if damage_flash_tween != null:
		damage_flash_tween.kill()
		damage_flash_tween = null

	modulate = default_modulate

func _build_damage_flash_sequence() -> Array[Color]:
	var sequence: Array[Color] = []

	for flash_color: Color in damage_flash_colors:
		var sanitized_color: Color = flash_color
		sanitized_color.a = default_modulate.a
		sequence.append(sanitized_color)

		if restore_default_between_flash_colors:
			sequence.append(default_modulate)

	if (
		not restore_default_between_flash_colors
		or sequence.is_empty()
		or sequence[sequence.size() - 1] != default_modulate
	):
		sequence.append(default_modulate)

	return sequence
