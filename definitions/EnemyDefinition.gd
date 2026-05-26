## Resource de configuração base de um inimigo.
##
## Responsabilidades:
## - definir atributos básicos;
## - definir ataques configuráveis;
## - definir fraquezas e resistências;
## - definir recompensas;
## - definir áreas vulneráveis independentes da colisão corporal;
## - definir visual e informações técnicas.
extends Resource
class_name EnemyDefinition

## ID técnico único do inimigo.
@export var id: String = ""

## Chave de localização utilizada para exibir o nome do inimigo.
@export var display_name_key: String = ""

## Chave de localização utilizada para exibir sua descrição.
@export var description_key: String = ""

@export_group("Base Attributes")

## Vida máxima inicial desta categoria de inimigo.
@export var base_max_hp: int = 10

## Velocidade base de perseguição.
@export var base_move_speed: float = 90.0

@export_group("Attacks")

## Ataque executado enquanto o inimigo encosta na PlayerHurtbox.
##
## No Goblin atual, representa o ataque corporal de contato.
@export var contact_attack: EnemyAttackDefinition

@export_group("Weaknesses and Resistances")

## Tipos de dano que recebem multiplicador positivo contra este inimigo.
@export var weak_damage_types: PackedStringArray = []

## Tipos de dano que recebem redução contra este inimigo.
@export var resistant_damage_types: PackedStringArray = []

## Percentual adicional aplicado quando houver fraqueza.
@export var weakness_bonus_percent: float = 50.0

## Percentual removido quando houver resistência.
@export var resistance_reduction_percent: float = 50.0

@export_group("Rewards")

## XP concedida diretamente à run ao derrotar este inimigo.
@export var xp_reward: int = 1

## Chance de gerar moeda física ao morrer.
## A moeda somente entra no saldo quando for coletada.
@export var coin_drop_chance: float = 0.25

## Valor da moeda física gerada quando o drop ocorrer.
@export var coin_drop_value: int = 1

@export_group("Hurtbox")

## Áreas vulneráveis que recebem ataques.
##
## Estas shapes são independentes da BodyCollision utilizada para movimento.
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")

## Cena visual real utilizada para representar o inimigo.
@export_file("*.tscn") var visual_scene_path: String = ""

## Resource Spine correspondente ao visual real.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

@export_group("Debug Placeholder")

## Cor utilizada por desenhos técnicos opcionais.
@export var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)

## Raio utilizado pelo placeholder visual técnico.
@export var debug_radius: float = 18.0

## Verifica se a definição possui identificação técnica.
func is_valid_definition() -> bool:
	return id.strip_edges() != ""

## Indica se o ataque de contato está configurado corretamente.
func has_valid_contact_attack() -> bool:
	return contact_attack != null and contact_attack.is_valid_definition()

## Indica se existe ao menos uma hurtbox válida configurada.
func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false

## Indica se o inimigo possui fraqueza ao tipo informado.
func is_weak_to_damage_type(damage_type: String) -> bool:
	return weak_damage_types.has(damage_type)

## Indica se o inimigo possui resistência ao tipo informado.
func is_resistant_to_damage_type(damage_type: String) -> bool:
	return resistant_damage_types.has(damage_type)
