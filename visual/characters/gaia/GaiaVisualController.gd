## Controller visual específico da Gaia.
##
## Responsabilidades:
## - converter estados runtime da personagem em animações Spine;
## - aplicar orientação horizontal baseada no movimento corporal;
## - executar flash visual quando a Gaia recebe dano;
## - executar blink visual periódico em track superior do Spine.
##
## A mira não controla o lado para o qual o corpo está virado.
## Essa decisão permanece no `PlayerRuntimeState`.
##
## O motor de blink pertence exclusivamente à camada visual:
## - não altera gameplay;
## - não altera movimento;
## - não altera ataque;
## - não altera hitbox/hurtbox;
## - não altera estado runtime da Queen.
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

@export_group("Blink Overlay")

## Ativa o motor visual de blink automático da Gaia.
@export var blink_enabled: bool = true

## Track Spine usada para o blink.
##
## A track 0 permanece reservada para idle/run/dash/death.
## O blink deve usar track 1 ou superior para mesclar com a animação base.
@export var blink_track_index: int = 1

## Menor intervalo possível entre blinks automáticos.
@export var blink_interval_min_seconds: float = 1.0

## Maior intervalo possível entre blinks automáticos.
@export var blink_interval_max_seconds: float = 7.0

## Animação de blink usada quando Gaia está em idle.
##
## Esta animação deve conter somente keys dos olhos/pálpebras para
## mesclar corretamente sobre o idle.
@export var idle_blink_animation_name: String = "Blink_Idle_Pose2"

## Animação de blink usada quando Gaia estiver correndo.
##
## Por enquanto pode ficar vazio.
## Quando existir uma animação de blink durante run, basta preencher.
@export var run_blink_animation_name: String = ""

## Animação de blink usada durante dash.
##
## Por enquanto pode ficar vazio.
@export var dash_blink_animation_name: String = ""

## Se verdadeiro, o motor tentará piscar durante dash quando
## `dash_blink_animation_name` estiver configurado.
@export var allow_blink_while_dashing: bool = false

## Tempo visual após o qual a track de blink será limpa.
##
## Deve ser próximo da duração real da animação de blink no Spine.
@export var blink_animation_duration_seconds: float = 0.22

## Se verdadeiro, o motor tentará piscar durante movimento quando
## `run_blink_animation_name` estiver configurado.
@export var allow_blink_while_running: bool = true

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

## Indica se uma animação temporária de blink está ativa na track overlay.
var is_blink_playing: bool = false

## Token incremental usado para invalidar timers antigos de blink.
##
## SceneTreeTimer não é cancelável diretamente. Incrementar este token
## permite ignorar callbacks antigos quando o blink é reagendado.
var blink_schedule_token: int = 0

## Último estado de gameplay recebido do PlayerController.
var last_gameplay_state: String = GameplayStateTypes.IDLE

## Armazena a cor original, inicializa o comportamento visual herdado
## e agenda o primeiro blink automático.
func _ready() -> void:
	default_modulate = modulate
	super._ready()
	_schedule_next_blink()

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
## - escolhe a animação base correspondente na track 0.
##
## O blink não bloqueia mais este fluxo, pois agora roda em track superior.
func apply_runtime_state(runtime_state: PlayerRuntimeState) -> void:
	if runtime_state == null:
		return

	_apply_horizontal_facing(runtime_state.facing_direction)

	var previous_gameplay_state: String = last_gameplay_state
	var gameplay_state: String = runtime_state.current_gameplay_state
	last_gameplay_state = gameplay_state

	# Ao trocar para um estado que não suporta blink overlay configurado,
	# limpamos a track superior para evitar poses residuais por cima de run/dash.
	if previous_gameplay_state != gameplay_state:
		if not _state_supports_blink_overlay(gameplay_state):
			_clear_blink_overlay_track()

	# A morte sempre tem prioridade visual absoluta sobre blink.
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
			play_dash()

		_:
			play_idle()

## Solicita a animação idle em loop na track base.
func play_idle() -> void:
	_play_animation_if_changed(
		idle_animation_name,
		true,
		GameplayStateTypes.IDLE
	)

## Solicita a animação de movimento em loop na track base.
func play_run() -> void:
	_play_animation_if_changed(
		run_animation_name,
		true,
		GameplayStateTypes.MOVING
	)

## Solicita a animação de dash sem repetição automática na track base.
##
## O dash ainda é um estado preparado para evolução futura do gameplay.
func play_dash() -> void:
	_play_animation_if_changed(
		dash_animation_name,
		false,
		GameplayStateTypes.DASHING
	)

## Solicita a animação de morte sem repetição automática na track base.
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

## Agenda o próximo blink automático usando intervalo aleatório configurável.
##
## O agendamento é visual e não afeta nenhum estado de gameplay.
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

## Tenta executar o blink quando o timer dispara.
##
## Se o estado atual não permitir blink, apenas agenda a próxima tentativa.
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

## Informa se o estado atual possui blink overlay configurado.
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

## Limpa somente a track overlay do blink.
##
## Não cancela timers futuros por si só; apenas remove pose residual.
func _clear_blink_overlay_track() -> void:
	is_blink_playing = false

	var safe_track_index: int = max(1, blink_track_index)
	_clear_animation_track(safe_track_index)

## Retorna qual animação de blink deve ser usada para o estado visual atual.
##
## Atualmente:
## - IDLE usa `idle_blink_animation_name`;
## - MOVING só usa blink se houver animação de run configurada;
## - DASHING só usa blink se permitido e houver animação configurada;
## - DEAD não pisca.
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
## Executa a animação temporária de blink em uma track superior.
##
## A animação base em track 0 continua rodando normalmente.
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

## Finaliza o blink temporário limpando apenas a track overlay.
##
## Não chama idle/run novamente, porque a track base nunca parou.
func _finish_blink_overlay() -> void:
	is_blink_playing = false

	var safe_track_index: int = max(1, blink_track_index)
	_clear_animation_track(safe_track_index)

	_schedule_next_blink()

## Cancela qualquer blink ativo ou agendado.
##
## Usado quando estados prioritários, como morte, precisam assumir
## controle visual imediatamente.
func _cancel_blink() -> void:
	blink_schedule_token += 1
	_clear_blink_overlay_track()
