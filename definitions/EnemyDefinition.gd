## Resource principal de configuração de um inimigo.
##
## Responsabilidades:
## - definir atributos básicos;
## - configurar ataque;
## - configurar fraquezas e resistências;
## - configurar recompensas;
## - configurar hurtboxes;
## - configurar visual;
## - configurar comportamento físico de bando, slide e knockback.
##
## Exemplo atual:
## - enemy_chaser_basic.tres, usado pelo Goblin perseguidor básico.
##
## Importante:
## A cena EnemyBase.tscn deve continuar genérica.
## O comportamento específico do inimigo deve vir deste resource.
extends Resource
class_name EnemyDefinition

## ID técnico único do inimigo.
@export var id: String = ""

## Chave de localização para nome exibido.
@export var display_name_key: String = ""

## Chave de localização para descrição.
@export var description_key: String = ""

@export_group("Base Attributes")

## HP máximo base do inimigo.
@export var base_max_hp: int = 10

## Velocidade base de perseguição/movimento.
@export var base_move_speed: float = 90.0

@export_group("Attacks")

## Ataque principal de contato do inimigo.
##
## Na arquitetura atual, o dano não vem da BodyCollision.
## Ele vem de EnemyAttackHitbox usando esta EnemyAttackDefinition.
@export var contact_attack: EnemyAttackDefinition

@export_group("Weaknesses and Resistances")

## Tipos de dano contra os quais este inimigo é fraco.
@export var weak_damage_types: PackedStringArray = []

## Tipos de dano contra os quais este inimigo é resistente.
@export var resistant_damage_types: PackedStringArray = []

## Bônus percentual aplicado quando o inimigo é fraco ao tipo recebido.
@export var weakness_bonus_percent: float = 50.0

## Redução percentual aplicada quando o inimigo resiste ao tipo recebido.
@export var resistance_reduction_percent: float = 50.0

@export_group("Rewards")

## XP direta concedida ao player quando o inimigo morre.
@export var xp_reward: int = 1

## Chance de dropar moeda física ao morrer.
@export var coin_drop_chance: float = 0.25

## Valor da moeda dropada, caso o drop aconteça.
@export var coin_drop_value: int = 1

@export_group("Hurtbox")

## Áreas vulneráveis do inimigo.
##
## DirectionalAttackHitbox da Gaia detecta EnemyHurtbox construída a partir
## dessas definições.
@export var hurtbox_areas: Array[HurtboxAreaDefinition] = []

@export_group("Visual")

## Cena visual do inimigo, podendo conter Spine ou placeholder.
@export_file("*.tscn") var visual_scene_path: String = ""

## Resource de skeleton Spine, se utilizado.
@export_file("*.tres") var spine_skeleton_data_resource_path: String = ""

@export_group("Debug Placeholder")

## Cor usada por placeholder/debug visual.
@export var debug_color: Color = Color(0.9, 0.15, 0.15, 1.0)

## Raio usado por placeholder/debug visual.
@export var debug_radius: float = 18.0

@export_group("Body Bump")

## Habilita esbarrão físico leve entre inimigos.
##
## Usado para reduzir empilhamento excessivo do bando.
@export var body_bump_enabled: bool = true

## Intensidade abstrata do esbarrão.
@export var body_bump_power: float = 2.0

## Conversão da intensidade em velocidade aplicada.
@export var body_bump_velocity_per_power: float = 24.0

## Velocidade máxima resultante do esbarrão.
@export var body_bump_max_velocity: float = 140.0

## Decaimento da velocidade de esbarrão por segundo.
@export var body_bump_decay_per_second: float = 280.0

## Quanto da resposta de esbarrão influencia lateralmente o inimigo.
@export_range(0.0, 1.0, 0.05) var body_bump_lateral_influence: float = 0.35

@export_group("Player Body Slide")

## Habilita o escorregamento do inimigo ao redor do corpo da Gaia.
##
## Ajuda a evitar que Goblins grudem na BodyCollision do player.
@export var player_body_slide_enabled: bool = true

## Intensidade abstrata do slide em contato com o corpo do player.
@export var player_body_slide_power: float = 2.0

## Conversão da intensidade do slide em velocidade.
@export var player_body_slide_velocity_per_power: float = 36.0

## Velocidade máxima do slide ao redor do player.
@export var player_body_slide_max_velocity: float = 160.0

## Decaimento da velocidade de slide por segundo.
@export var player_body_slide_decay_per_second: float = 360.0

## Quanto o slide empurra o inimigo para longe da Gaia.
##
## Valores baixos preservam perseguição.
## Valores altos afastam mais agressivamente.
@export_range(0.0, 1.0, 0.05)
var player_body_slide_away_influence: float = 0.30

@export_group("Received Knockback")

## Multiplicador aplicado ao knockback recebido de arma, dash ou efeitos futuros.
@export var received_knockback_multiplier: float = 1.0

## Velocidade máxima de knockback recebido.
@export var received_knockback_max_velocity: float = 520.0

## Decaimento da velocidade de knockback por segundo.
@export var received_knockback_decay_per_second: float = 1800.0

## Quanto o inimigo continua tentando perseguir enquanto sofre knockback.
##
## 0 = knockback domina totalmente.
## 1 = perseguição pesa muito durante o knockback.
@export_range(0.0, 1.0, 0.05) var received_knockback_chase_weight: float = 0.15

## Verifica se a definição possui ID válido.
func is_valid_definition() -> bool:
	return id.strip_edges() != ""

## Informa se o inimigo possui ataque de contato válido.
func has_valid_contact_attack() -> bool:
	return contact_attack != null and contact_attack.is_valid_definition()

## Informa se existe pelo menos uma hurtbox válida configurada.
func has_valid_hurtbox_areas() -> bool:
	for hurtbox_area: HurtboxAreaDefinition in hurtbox_areas:
		if hurtbox_area == null:
			continue

		if hurtbox_area.is_valid_definition():
			return true

	return false

## Verifica se este inimigo é fraco a determinado tipo de dano.
func is_weak_to_damage_type(damage_type: String) -> bool:
	return weak_damage_types.has(damage_type)

## Verifica se este inimigo é resistente a determinado tipo de dano.
func is_resistant_to_damage_type(damage_type: String) -> bool:
	return resistant_damage_types.has(damage_type)
