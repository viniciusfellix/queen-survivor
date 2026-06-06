## Resource semântico para áreas ofensivas.
##
## Responsabilidades:
## - representar uma área de ataque configurável;
## - reutilizar toda a lógica geométrica de CombatShapeDefinition;
## - permitir que armas e ataques definam suas áreas por resource;
## - diferenciar semanticamente uma área ofensiva de uma hurtbox.
##
## Exemplo atual:
## - área retangular da arma inicial da Gaia.
##
## Observação:
## Este script não adiciona campos novos porque, por enquanto,
## toda a geometria necessária já está em CombatShapeDefinition.
extends CombatShapeDefinition
class_name AttackAreaDefinition
