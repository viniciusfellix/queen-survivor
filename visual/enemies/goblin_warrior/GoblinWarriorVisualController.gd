## Controller visual específico do Goblin Warrior.
##
## Responsabilidades:
## - alternar entre animações idle, run e death;
## - inverter horizontalmente o inimigo conforme sua movimentação;
## - utilizar animação alternativa de caminhada quando configurado.
##
## Este controller apenas representa visualmente o estado recebido.
## Movimento, ataque e morte são decididos por `EnemyBase`.
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
