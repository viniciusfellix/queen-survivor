## Resource de balanceamento de um tipo de inimigo.
##
## Este é um dos principais arquivos editáveis pelo game designer.
## Nele podem ser configurados:
## - vida e velocidade;
## - dano de contato;
## - fraquezas e resistências;
## - XP concedida;
## - chance e valor de moeda;
## - visual real ou placeholder.
extends Resource
class_name EnemyDefinition

## ID técnico único do tipo de inimigo.
##
## Exemplo atual: `enemy_chaser_basic`.
@export var id: String = ""

## Chave de localização utilizada para o nome do inimigo.
@export var display_name_key: String = ""

## Chave de localização utilizada para a descrição do inimigo.
@export var description_key: String = ""

## Vida máxima inicial de cada instância deste inimigo.
@export var base_max_hp: int = 10

## Velocidade base de perseguição/movimento do inimigo.
@export var base_move_speed: float = 90.0

## Dano bruto causado quando o inimigo entra em contato com a Queen.
@export var contact_damage: int = 5

## Distância máxima para considerar contato ofensivo com a Queen.
@export var contact_damage_radius: float = 32.0

## Intervalo mínimo, em segundos, entre danos consecutivos de contato.
@export var contact_damage_interval_seconds: float = 1.0

## Tipo do dano causado pelo contato.
##
## O tipo pode interagir com sistemas futuros de defesa ou efeitos.
@export var contact_damage_type: String = DamageTypes.PHYSICAL

## Tipos de dano aos quais este inimigo possui fraqueza.
##
## Quando atingido por um tipo listado aqui, recebe o bônus configurado
## em `weakness_bonus_percent`.
@export var weak_damage_types: PackedStringArray = []

## Tipos de dano aos quais este inimigo possui resistência.
##
## Quando atingido por um tipo listado aqui, sofre a redução configurada
## em `resistance_reduction_percent`.
@export var resistant_damage_types: PackedStringArray = []

## Percentual adicional de dano recebido para cada componente fraco.
##
## Exemplo: `50.0` transforma 3 de dano em aproximadamente 5 após arredondamento.
@export var weakness_bonus_percent: float = 50.0

## Percentual reduzido de dano recebido para cada componente resistido.
##
## Exemplo: `50.0` transforma 3 de dano em aproximadamente 2 após arredondamento.
@export var resistance_reduction_percent: float = 50.0

## XP concedida diretamente à run ao derrotar este inimigo.
@export var xp_reward: int = 1

## Chance, entre `0.0` e `1.0`, de gerar moeda física ao morrer.
##
## Exemplo: `0.20` representa 20% de chance de drop.
@export var coin_drop_chance: float = 0.25

## Valor da moeda física criada quando o drop ocorre.
##
## A moeda só entra no saldo quando for coletada pela Queen.
@export var coin_drop_value: int = 1

## Cena visual real opcional associada ao inimigo.
@export_file("*.tscn") var visual_scene_path: String = ""

## Resource Spine opcional utilizado pelo visual real do inimigo.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

## Cor utilizada por visuais de placeholder ou debug.
@export var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)

## Raio visual utilizado por placeholders ou desenhos técnicos do inimigo.
@export var debug_radius: float = 18.0

## Verifica se a definição possui ao menos um ID técnico válido.
func is_valid_definition() -> bool:
	return id.strip_edges() != ""

## Informa se este inimigo é fraco contra determinado tipo de dano.
func is_weak_to_damage_type(damage_type: String) -> bool:
	return weak_damage_types.has(damage_type)

## Informa se este inimigo é resistente contra determinado tipo de dano.
func is_resistant_to_damage_type(damage_type: String) -> bool:
	return resistant_damage_types.has(damage_type)
