## Resource que representa uma parcela individual de dano de uma arma.
##
## Uma arma pode possuir vários componentes simultâneos.
## Exemplo atual da Gaia:
## - componente físico;
## - componente mágico.
extends Resource
class_name DamageComponentDefinition

## Tipo elemental ou estrutural deste componente.
@export var damage_type: String = DamageTypes.PHYSICAL

## Valor bruto causado por este componente.
@export var amount: int = 1

## Define se este componente recebe bônus quando o inimigo
## possui fraqueza ao tipo correspondente.
@export var affected_by_weakness: bool = true

## Define se este componente sofre redução quando o inimigo
## possui resistência ao tipo correspondente.
@export var affected_by_resistance: bool = true

## Verifica se o componente possui dano positivo e tipo reconhecido.
func is_valid_component() -> bool:
	return amount > 0 and DamageTypes.is_valid_type(damage_type)
