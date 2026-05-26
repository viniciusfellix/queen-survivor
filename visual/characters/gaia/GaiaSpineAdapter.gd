## Adapter Spine específico da Gaia.
##
## Herda toda a integração com o plugin Spine da classe base.
## A Gaia publica mudanças de animação porque o DebugOverlay
## acompanha a animação atual da personagem controlada.
extends "res://visual/spine/SpineAnimationAdapterBase.gd"

## Habilita a publicação do signal global de mudança de animação.
func _should_publish_animation_changed() -> bool:
	return true

## Define o identificador utilizado em logs técnicos.
func _get_adapter_log_name() -> String:
	return "GaiaSpineAdapter"
