## Controller visual específico do Goblin Warrior.
##
## Responsabilidades:
## - alternar entre animações idle, run e death;
## - inverter horizontalmente o inimigo conforme sua movimentação;
## - executar flash claro ao receber dano;
## - utilizar animação alternativa de caminhada quando configurado.
##
## Este controller apenas representa visualmente o estado recebido.
## Movimento, ataque, dano e morte são decididos por `EnemyBase`.
extends "res://visual/spine/SpineVisualControllerBase.gd"

@export_group("Animations")

## Animação utilizada quando o Goblin está parado.
@export var idle_animation_name: String = "Idle"

## Animação principal utilizada durante perseguição/movimento.
@export var run_animation_name: String = "Run"

## Animação alternativa utilizada quando `run_animation_name` estiver vazio.
@export var walk_animation_name: String = "Run"

## Animação executada quando o Goblin morre.
@export var death_animation_name: String = "Die"

@export_group("Behaviour")

## Autoriza utilizar `walk_animation_name` quando não houver animação run.
@export var use_walk_when_run_missing: bool = true

## Define se o visual deve ser espelhado conforme a direção horizontal.
@export var flip_by_movement_direction: bool = true

@export_group("Damage Flash")

## Intensidade clara aplicada durante o impacto.
##
## `Color.WHITE` comum não altera o visual, pois representa a modulação
## padrão. Valores acima de 1.0 produzem um clarão visível no Spine.
@export_range(1.0, 8.0, 0.1) var damage_flash_brightness: float = 4.0

## Tempo em que o clarão permanece no pico antes de começar a desaparecer.
@export var damage_flash_hold_seconds: float = 0.035

## Duração da transição entre o clarão e a aparência normal.
@export var damage_flash_duration: float = 0.12

var damage_flash_tween: Tween = null
var default_modulate: Color = Color.WHITE

## Registra a modulação original antes da inicialização visual base.
func _ready() -> void:
	default_modulate = modulate
	super._ready()

## Define o identificador utilizado nos logs deste controller.
func _get_visual_log_name() -> String:
	return "GoblinWarriorVisualController"

## Inicia o inimigo em sua animação idle.
func _play_initial_animation() -> void:
	play_idle()

## Aplica visualmente o estado runtime recebido do inimigo.
##
## Enquanto vivo, escolhe idle ou run conforme movimentação.
## Quando morto, aplica death e interrompe as demais decisões visuais.
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

## Solicita a animação idle em loop.
func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		"idle"
	)

## Solicita a animação de movimento em loop.
##
## Caso a animação principal esteja vazia, utiliza o fallback
## de caminhada quando essa possibilidade estiver habilitada.
func play_run() -> void:
	var selected_animation: String = run_animation_name

	if selected_animation.strip_edges() == "" and use_walk_when_run_missing:
		selected_animation = walk_animation_name

	_play_animation_if_changed(
		selected_animation,
		true,
		"run"
	)

## Solicita a animação de morte sem repetição automática.
func play_death() -> void:
	_play_animation_if_changed(
		death_animation_name,
		false,
		"death"
	)

## Executa um clarão branco breve ao receber dano.
##
## Caso outro impacto aconteça antes do término do flash anterior,
## reinicia o tween para manter o feedback responsivo.
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
