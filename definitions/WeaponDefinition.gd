## Resource de configuração base de uma arma.
##
## Responsabilidades:
## - definir identificação e localization;
## - definir cooldown;
## - definir visual temporário do ataque;
## - definir cena runtime da hitbox;
## - definir uma ou mais áreas de acerto configuráveis;
## - definir componentes de dano.
##
## A arma não executa ataques diretamente.
## Controllers runtime consomem esta configuração durante a run.
extends Resource
class_name WeaponDefinition

@export var id: String = ""
@export var display_name_key: String = ""
@export var description_key: String = ""

## Level máximo planejado para armas.
@export var max_level: int = 10

## Intervalo base entre ataques.
@export var cooldown_seconds: float = 2.0

@export_group("Attack Visual")

## Distância entre a Queen e o visual temporário do golpe.
@export var attack_visual_offset: float = 86.0

## Tempo de exibição do visual temporário.
@export var attack_visual_lifetime: float = 0.22

## Cena visual instanciada a cada ataque.
@export_file("*.tscn") var attack_visual_scene_path: String = ""

@export_group("Attack Hitbox")

## Cena runtime responsável por avaliar acertos.
@export_file("*.tscn") var attack_hitbox_scene_path: String = "res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn"

## Distância entre a Queen e o ponto base onde a hitbox é instanciada.
##
## Cada AttackAreaDefinition ainda pode aplicar seu próprio local_offset.
@export var attack_hitbox_offset: float = 86.0

## Tempo durante o qual a hitbox permanece ativa.
@export var attack_hitbox_lifetime: float = 0.12

## Áreas de acerto da arma.
##
## Cada item permite escolher um Shape2D nativo no Inspector.
## Uma arma simples terá uma área; ataques mais complexos poderão
## combinar mais de uma área sem alterar o controller.
@export var attack_areas: Array[AttackAreaDefinition] = []

@export_group("On Hit Effects")

## Define se esta arma aplica knockback em inimigos atingidos.
##
## O knockback só é aplicado quando o dano foi aceito pelo receiver.
## Isso evita empurrar inimigos mortos, invulneráveis ou que não receberam dano.
@export var hit_knockback_enabled: bool = false

## Distância aproximada, em pixels, que a arma tenta empurrar o inimigo.
##
## O deslocamento real pode ser menor se houver colisão física no caminho,
## pois o inimigo continua usando CharacterBody2D e move_and_slide().
@export var hit_knockback_pixels: float = 0.0

## Duração, em segundos, usada para distribuir o knockback.
##
## Valores muito baixos deixam o impacto seco.
## Valores maiores deixam o inimigo deslizar por mais tempo.
@export var hit_knockback_duration_seconds: float = 0.12

@export_group("Damage")

## Modelo oficial atual: uma arma pode possuir um ou mais componentes
## de dano no mesmo ataque.
##
## Exemplo atual da Gaia:
## - dano físico;
## - dano mágico.
@export var damage_components: Array[DamageComponentDefinition] = []

## Fallback para armas simples sem componentes cadastrados.
##
## Quando `damage_components` estiver preenchido,
## a lista de componentes prevalece.
@export var base_damage: int = 5

## Tipo de dano usado pelo fallback simples.
@export var damage_type: String = DamageTypes.PHYSICAL

## Valida se a definição possui id e ao menos uma área ofensiva válida.
func is_valid_definition() -> bool:
	return id.strip_edges() != "" and has_valid_attack_areas()

## Informa se a arma utiliza componentes de dano compostos.
func has_damage_components() -> bool:
	return not damage_components.is_empty()

## Informa se ao menos uma área configurada pode ser utilizada no runtime.
func has_valid_attack_areas() -> bool:
	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if attack_area.is_valid_definition():
			return true

	return false

## Retorna descrição textual das áreas para logs de configuração.
func get_attack_areas_debug_summary(scale_multiplier: float = 1.0) -> String:
	var summaries: Array[String] = []

	for attack_area: AttackAreaDefinition in attack_areas:
		if attack_area == null:
			continue

		if not attack_area.is_valid_definition():
			continue

		summaries.append(attack_area.get_debug_summary(scale_multiplier))

	if summaries.is_empty():
		return "none"

	return ", ".join(summaries)
