## Resource que representa um componente individual de dano.
##
## Responsabilidades:
## - definir tipo de dano;
## - definir quantidade bruta;
## - informar se o componente é afetado por fraqueza;
## - informar se o componente é afetado por resistência.
##
## Uma arma pode ter vários componentes.
##
## Exemplo da Gaia:
## - componente físico;
## - componente mágico.
##
## Isso evita criar um tipo especial "híbrido" e permite que o
## DamageResolver calcule cada parte separadamente.
extends Resource
class_name DamageComponentDefinition

## Tipo do dano deste componente.
##
## Deve ser um valor válido de DamageTypes.
@export var damage_type: String = DamageTypes.PHYSICAL

## Quantidade bruta de dano deste componente.
@export var amount: int = 1

## Define se este componente recebe bônus de fraqueza do alvo.
@export var affected_by_weakness: bool = true

## Define se este componente sofre redução por resistência do alvo.
@export var affected_by_resistance: bool = true

## Verifica se o componente possui configuração válida.
##
## Requisitos:
## - amount maior que zero;
## - damage_type reconhecido por DamageTypes.
func is_valid_component() -> bool:
	return amount > 0 and DamageTypes.is_valid_type(damage_type)
