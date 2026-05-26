## Resource de configuração de uma opção de upgrade durante a run.
##
## Cada arquivo `.tres` deste tipo representa um card exibível no level-up.
## O game designer pode configurar:
## - nome e descrição;
## - ícone;
## - tipo de efeito;
## - valor aplicado;
## - limite de stacks;
## - exibição do badge de nível.
extends Resource
class_name UpgradeDefinition

## ID técnico único do upgrade.
##
## Exemplo: `upgrade_weapon_magical_damage_flat`.
@export var id: String = ""

## Chave de localização utilizada para nome do card.
@export var display_name_key: String = ""

## Chave de localização utilizada para descrição do card.
@export var description_key: String = ""

## Ícone exibido no card de level-up.
@export var icon: Texture2D

## Tipo funcional do upgrade.
##
## Deve corresponder a uma constante válida de `UpgradeTypes`.
@export var upgrade_type: String = ""

## Valor inteiro utilizado por upgrades de efeito fixo.
##
## Exemplos:
## - HP máximo;
## - cura;
## - dano flat;
## - raio flat de hitbox.
@export var value_int: int = 0

## Valor decimal utilizado por upgrades percentuais.
##
## Exemplos:
## - velocidade;
## - defesa;
## - cooldown;
## - magnetismo;
## - duração da hitbox.
@export var value_float: float = 0.0

## Limite de vezes que este upgrade pode ser escolhido na mesma run.
##
## Valores altos permitem comportamento praticamente ilimitado no protótipo.
## Futuramente esta estrutura poderá evoluir para steps variáveis por stack.
@export var max_stack_in_run: int = 999

## Define se o card exibe badge de nível/stack durante a run.
##
## Upgrades instantâneos, como cura, poderão futuramente desativar este badge.
@export var show_level_badge: bool = true

## Verifica se o card possui os dados mínimos para participar da pool.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and display_name_key.strip_edges() != ""
		and upgrade_type.strip_edges() != ""
	)
