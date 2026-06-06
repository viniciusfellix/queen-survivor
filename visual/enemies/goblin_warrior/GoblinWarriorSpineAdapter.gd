## Adapter Spine específico do Goblin Warrior.
##
## Responsabilidade:
## - herdar toda a lógica base de SpineAnimationAdapterBase;
## - fornecer nome específico para logs técnicos.
##
## Este script existe para manter a arquitetura visual específica por personagem,
## mesmo que atualmente não adicione comportamento próprio.
extends "res://visual/spine/SpineAnimationAdapterBase.gd"

## Nome usado nos logs do adapter.
func _get_adapter_log_name() -> String:
	return "GoblinWarriorSpineAdapter"
