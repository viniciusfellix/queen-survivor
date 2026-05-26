## Controller visual específico da Gaia.
##
## Responsabilidades:
## - converter estados runtime da personagem em animações Spine;
## - aplicar orientação horizontal baseada no movimento corporal;
## - executar flash visual quando a Gaia recebe dano.
##
## A mira não controla o lado para o qual o corpo está virado.
## Essa decisão permanece no `PlayerRuntimeState`.
extends "res://visual/spine/SpineVisualControllerBase.gd"

@export_group("Animations")

## Animação padrão quando a Gaia está parada.
@export var idle_animation_name: String = "Idle1_Pose2"

## Animação executada enquanto a Gaia se movimenta.
@export var run_animation_name: String = "Run1_Pose3"

## Animação prevista para deslocamento rápido futuro.
@export var dash_animation_name: String = "Dash1_Pose3"

## Animação executada quando a Gaia morre.
@export var death_animation_name: String = "Die_Pose1"

@export_group("Damage Flash")

## Cor aplicada temporariamente ao visual quando a Gaia recebe dano.
@export var damage_flash_color: Color = Color(1.0, 0.25, 0.25, 1.0)

## Tempo necessário para o visual retornar à cor original.
@export var damage_flash_duration: float = 0.12

## Tween atualmente responsável pelo flash de dano.
##
## Mantido em referência para cancelar um flash anterior
## caso outro dano seja recebido antes de sua conclusão.
var damage_flash_tween: Tween = null

## Cor original do visual, restaurada ao final do flash.
var default_modulate: Color = Color.WHITE

## Armazena a cor original e inicializa o comportamento visual herdado.
func _ready() -> void:
	default_modulate = modulate
	super._ready()

## Define o identificador utilizado nos logs deste controller.
func _get_visual_log_name() -> String:
	return "GaiaVisualController"

## Inicia a Gaia em sua animação ociosa padrão.
func _play_initial_animation() -> void:
	play_idle()

## Aplica visualmente o estado runtime atual da Gaia.
##
## Este método:
## - ajusta orientação horizontal;
## - registra o estado visual no runtime state;
## - escolhe a animação correspondente.
func apply_runtime_state(runtime_state: PlayerRuntimeState) -> void:
	if runtime_state == null:
		return

	_apply_horizontal_facing(runtime_state.facing_direction)

	var gameplay_state: String = runtime_state.current_gameplay_state

	runtime_state.current_visual_state = gameplay_state

	match gameplay_state:
		GameplayStateTypes.IDLE:
			play_idle()

		GameplayStateTypes.MOVING:
			play_run()

		GameplayStateTypes.DASHING:
			play_dash()

		GameplayStateTypes.DEAD:
			play_death()

		_:
			play_idle()

## Solicita a animação idle em loop.
func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		GameplayStateTypes.IDLE
	)

## Solicita a animação de movimento em loop.
func play_run() -> void:
	_play_animation_if_changed(
		run_animation_name,
		true,
		GameplayStateTypes.MOVING
	)

## Solicita a animação de dash sem repetição automática.
##
## O dash ainda é um estado preparado para evolução futura do gameplay.
func play_dash() -> void:
	_play_animation_if_changed(
		dash_animation_name,
		false,
		GameplayStateTypes.DASHING
	)

## Solicita a animação de morte sem repetição automática.
func play_death() -> void:
	_play_animation_if_changed(
		death_animation_name,
		false,
		GameplayStateTypes.DEAD
	)

## Executa o feedback visual de dano sobre a Gaia.
##
## Caso um flash anterior ainda esteja ativo, ele é cancelado
## antes de iniciar a nova transição de retorno à cor original.
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
