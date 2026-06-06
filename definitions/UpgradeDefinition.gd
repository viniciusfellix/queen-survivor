## Resource que define um upgrade individual da run.
##
## Responsabilidades:
## - identificar o upgrade;
## - apontar textos localizados;
## - guardar ícone;
## - definir tipo técnico do efeito;
## - armazenar valores numéricos;
## - definir limite de stacks por run;
## - controlar exibição de badge de nível/stack.
##
## Este resource descreve o upgrade.
## A aplicação real do efeito acontece nos controllers/services responsáveis.
extends Resource
class_name UpgradeDefinition

## ID técnico único do upgrade.
@export var id: String = ""

## Chave de localização para nome exibido.
@export var display_name_key: String = ""

## Chave de localização para descrição.
@export var description_key: String = ""

## Ícone exibido no card de level-up.
@export var icon: Texture2D

## Tipo técnico do upgrade.
##
## Deve corresponder a uma constante de UpgradeTypes.
@export var upgrade_type: String = ""

## Valor inteiro do upgrade.
##
## Usado para efeitos como HP fixo, cura fixa ou dano flat.
@export var value_int: int = 0

## Valor decimal do upgrade.
##
## Usado para percentuais, multiplicadores ou escalas.
@export var value_float: float = 0.0

## Quantas vezes este upgrade pode ser escolhido na mesma run.
@export var max_stack_in_run: int = 999

## Define se o card deve mostrar badge de nível/stack.
##
## Pode ser falso para upgrades instantâneos, como cura.
@export var show_level_badge: bool = true

## Verifica se o upgrade possui configuração mínima válida.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and upgrade_type.strip_edges() != ""
	)
