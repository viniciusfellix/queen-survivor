## Resource semântico para áreas vulneráveis.
##
## Responsabilidades:
## - representar uma região que pode receber dano;
## - reutilizar toda a geometria configurável de CombatShapeDefinition;
## - diferenciar semanticamente áreas vulneráveis de áreas ofensivas.
##
## Exemplo atual:
## - hurtbox da Gaia;
## - hurtbox corporal do Goblin.
##
## Este script não adiciona campos porque a geometria já está toda na classe base.
extends CombatShapeDefinition
class_name HurtboxAreaDefinition
