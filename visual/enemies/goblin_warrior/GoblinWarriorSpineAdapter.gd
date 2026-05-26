## Adapter Spine específico do Goblin Warrior.
##
## Herda da base a busca do SpineSprite e a execução de animações.
## Diferentemente da Gaia, não publica mudança global de animação,
## pois o overlay técnico atual acompanha prioritariamente o player.
extends "res://visual/spine/SpineAnimationAdapterBase.gd"

## Define o identificador utilizado em logs técnicos.
func _get_adapter_log_name() -> String:
	return "GoblinWarriorSpineAdapter"
