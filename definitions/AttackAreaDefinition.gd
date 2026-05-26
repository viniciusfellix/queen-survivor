## Área ofensiva pertencente a uma fonte de dano.
##
## Esta classe herda toda a configuração geométrica comum de
## CombatShapeDefinition e existe para diferenciar semanticamente
## regiões que causam dano de regiões que recebem dano.
##
## Pode ser utilizada por:
## - armas de Queens;
## - ataques corporais de inimigos;
## - projéteis;
## - ataques especiais futuros.
extends CombatShapeDefinition
class_name AttackAreaDefinition
