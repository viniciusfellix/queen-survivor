## Resource de configuração do dash de uma Queen.
##
## Responsabilidades:
## - configurar movimento do dash;
## - configurar invulnerabilidade durante dash;
## - configurar regras da arma durante dash;
## - configurar impacto, knockback e dano opcional;
## - configurar áreas de impacto;
## - configurar animações e comportamento visual.
##
## Importante:
## O PlayerController executa o dash, mas as regras específicas vêm deste resource.
## Isso permite que futuras Queens tenham dashes diferentes sem hardcode.
extends Resource
class_name QueenDashDefinition

## ID técnico único da configuração de dash.
@export var id: String = ""

@export_group("Movement")

## Habilita ou desabilita dash para esta Queen.
@export var dash_enabled: bool = true

## Distância percorrida pelo dash.
@export var dash_distance_pixels: float = 180.0

## Duração do dash em segundos.
@export var dash_duration_seconds: float = 0.18

## Cooldown próprio do dash.
@export var dash_cooldown_seconds: float = 1.25

@export_group("Damage Rules")

## Define se a Queen ignora dano enquanto está em dash.
@export var ignore_damage_while_dashing: bool = true

@export_group("Weapon Rules")

## Define se a arma pode atacar durante o dash.
@export var allow_weapon_attacks_while_dashing: bool = false

## Define se o cooldown da arma fica pausado durante o dash.
@export var pause_weapon_cooldown_while_dashing: bool = true

## Define se o cooldown da arma reseta ao iniciar o dash.
@export var reset_weapon_cooldown_when_dash_starts: bool = false

## Define se o cooldown da arma reseta ao terminar o dash.
@export var reset_weapon_cooldown_when_dash_ends: bool = true

@export_group("Impact Knockback")

## Habilita impacto do dash contra inimigos.
@export var impact_enabled: bool = true

## Distância/intensidade base do knockback causado pelo dash.
@export var impact_knockback_pixels: float = 450.0

## Duração usada para converter knockback em velocidade.
@export var impact_knockback_duration_seconds: float = 0.20

## Se true, cada inimigo é atingido apenas uma vez por dash.
@export var hit_once_per_enemy: bool = true

## ID usado como fonte do impacto do dash.
@export var impact_source_id: String = "queen_dash"

## Modo usado para calcular direção do knockback.
##
## dash_direction: empurra na direção do dash.
## away_from_gaia: empurra para longe da Gaia.
## corridor: empurra lateralmente/abre caminho.
@export_enum("dash_direction", "away_from_gaia", "corridor")
var impact_direction_mode: String = "corridor"

## No modo corridor, define quanto da direção frontal do dash entra no empurrão.
@export_range(0.0, 1.0, 0.05)
var impact_forward_component: float = 0.15

## Override opcional para velocidade máxima de knockback no inimigo.
@export var impact_knockback_max_velocity_override: float = 1600.0

## Override opcional para peso de perseguição durante o knockback.
##
## -1 pode indicar comportamento padrão, dependendo da implementação.
@export_range(-1.0, 1.0, 0.05)
var impact_chase_weight_override: float = 0.0

@export_group("Impact Damage")

## Habilita dano no dash.
##
## Se false, o dash pode aplicar apenas knockback.
@export var impact_damage_enabled: bool = false

## Dano bruto fallback do dash.
@export var impact_raw_damage: int = 0

## Tipo do dano fallback do dash.
@export var impact_damage_type: String = DamageTypes.PHYSICAL

## Componentes compostos de dano do dash.
##
## Se preenchido, permite dano composto como físico + mágico.
@export var impact_damage_components: Array[DamageComponentDefinition] = []

@export_group("Impact Areas")

## Multiplicador base da área de impacto do dash.
@export var impact_area_scale_multiplier: float = 1.0

## Áreas ofensivas do impacto do dash.
@export var impact_areas: Array[AttackAreaDefinition] = []

@export_group("Visual")

## Animação lateral do dash.
@export var dash_side_animation_name: String = "Dash1_Pose3"

## Animação de dash para cima.
@export var dash_up_animation_name: String = ""

## Animação de dash para baixo.
@export var dash_down_animation_name: String = ""

## Limite vertical usado para decidir se a direção é cima/baixo ou lateral.
@export_range(0.0, 1.0, 0.05) var dash_vertical_threshold: float = 0.55

## Duração original da animação usada como base para calcular aceleração.
@export var dash_animation_source_duration_seconds: float = 3.0

## Se true, ajusta velocidade da animação para caber na duração do dash.
@export var match_animation_speed_to_dash_duration: bool = true

## Permite ou bloqueia blink overlay durante dash.
@export var allow_blink_while_dashing: bool = false

## Nome da animação de blink usada durante dash, se configurada.
@export var dash_blink_animation_name: String = ""

## Verifica se o dash possui configuração mínima válida.
func is_valid_definition() -> bool:
	return (
		id.strip_edges() != ""
		and dash_duration_seconds > 0.0
		and dash_distance_pixels > 0.0
		and dash_cooldown_seconds >= 0.0
	)

## Verifica se existe pelo menos uma área de impacto válida.
func has_valid_impact_areas() -> bool:
	for impact_area: AttackAreaDefinition in impact_areas:
		if impact_area == null:
			continue

		if impact_area.is_valid_definition():
			return true

	return false

## Verifica se o dash possui dano de impacto válido.
##
## Pode ser válido por dano fallback ou por componentes compostos.
func has_valid_impact_damage() -> bool:
	if impact_damage_components.is_empty():
		return impact_raw_damage > 0 and DamageTypes.is_valid_type(impact_damage_type)

	for component: DamageComponentDefinition in impact_damage_components:
		if component == null:
			continue

		if component.is_valid_component():
			return true

	return false
