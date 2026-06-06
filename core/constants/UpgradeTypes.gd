## Catálogo central dos tipos de upgrades da run.
##
## Responsabilidades:
## - padronizar IDs técnicos de upgrade;
## - separar upgrades de player e upgrades de arma;
## - evitar strings duplicadas espalhadas pelo projeto;
## - facilitar validação por serviços como LevelUpOptionService,
##   PlayerController e GaiaInitialWeaponController.
##
## Importante:
## Este arquivo define tipos, mas não aplica os efeitos.
## A aplicação real acontece nos sistemas responsáveis:
## - PlayerController para upgrades do player/Gaia;
## - GaiaInitialWeaponController para upgrades da arma;
## - outros controllers futuros para artefatos, summons etc.
extends RefCounted
class_name UpgradeTypes

## Aumenta velocidade de movimento do player em percentual.
const PLAYER_MOVE_SPEED_PERCENT: String = "player_move_speed_percent"

## Aumenta HP máximo do player em valor fixo.
const PLAYER_MAX_HP_FLAT: String = "player_max_hp_flat"

## Aumenta defesa do player em percentual.
const PLAYER_DEFENSE_PERCENT: String = "player_defense_percent"

## Cura o player em valor fixo.
const PLAYER_HEAL_FLAT: String = "player_heal_flat"

## Aumenta o dano geral da arma em valor fixo.
##
## Em armas compostas, a regra atual pode aplicar o valor em múltiplos
## componentes, conforme implementação do controller da arma.
const WEAPON_DAMAGE_FLAT: String = "weapon_damage_flat"

## Reduz cooldown da arma em percentual.
const WEAPON_COOLDOWN_PERCENT: String = "weapon_cooldown_percent"

## Aumenta apenas componentes físicos da arma.
const WEAPON_PHYSICAL_DAMAGE_FLAT: String = "weapon_physical_damage_flat"

## Aumenta apenas componentes mágicos da arma.
const WEAPON_MAGICAL_DAMAGE_FLAT: String = "weapon_magical_damage_flat"

## Escala percentualmente as áreas ofensivas configuradas da arma.
##
## Substitui o antigo conceito de aumentar raio fixo de hitbox.
## Funciona melhor com AttackAreaDefinition/CombatShapeDefinition.
const WEAPON_ATTACK_AREA_SCALE_PERCENT: String = "weapon_attack_area_scale_percent"

## Aumenta percentualmente a duração ativa da hitbox/área ofensiva da arma.
const WEAPON_HITBOX_LIFETIME_PERCENT: String = "weapon_hitbox_lifetime_percent"

## Aumenta o raio de magnetismo das moedas em percentual.
const COIN_MAGNET_RADIUS_PERCENT: String = "coin_magnet_radius_percent"

## Aumenta o raio final de coleta das moedas em percentual.
const COIN_COLLECT_RADIUS_PERCENT: String = "coin_collect_radius_percent"

## Aumenta distância do dash em percentual.
##
## Tipo preparado para upgrades futuros do dash.
const PLAYER_DASH_DISTANCE_PERCENT: String = "player_dash_distance_percent"

## Aumenta velocidade efetiva do dash em percentual.
##
## Tipo preparado para upgrades futuros do dash.
const PLAYER_DASH_SPEED_PERCENT: String = "player_dash_speed_percent"

## Escala a área de impacto do dash em percentual.
##
## Tipo preparado para upgrades futuros ligados ao PlayerDashImpactArea.
const PLAYER_DASH_IMPACT_AREA_SCALE_PERCENT: String = "player_dash_impact_area_scale_percent"

## Verifica se um tipo de upgrade pertence ao grupo de upgrades do player.
##
## Upgrades deste grupo normalmente são aplicados pelo PlayerController
## ou por componentes relacionados ao estado da Gaia.
static func is_player_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		PLAYER_MOVE_SPEED_PERCENT,
		PLAYER_MAX_HP_FLAT,
		PLAYER_DEFENSE_PERCENT,
		PLAYER_HEAL_FLAT,
		COIN_MAGNET_RADIUS_PERCENT,
		COIN_COLLECT_RADIUS_PERCENT,
		PLAYER_DASH_DISTANCE_PERCENT,
		PLAYER_DASH_SPEED_PERCENT,
		PLAYER_DASH_IMPACT_AREA_SCALE_PERCENT
	]

## Verifica se um tipo de upgrade pertence ao grupo de upgrades de arma.
##
## Upgrades deste grupo normalmente são aplicados pelo controller da arma
## equipada, como GaiaInitialWeaponController.
static func is_weapon_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		WEAPON_DAMAGE_FLAT,
		WEAPON_COOLDOWN_PERCENT,
		WEAPON_PHYSICAL_DAMAGE_FLAT,
		WEAPON_MAGICAL_DAMAGE_FLAT,
		WEAPON_ATTACK_AREA_SCALE_PERCENT,
		WEAPON_HITBOX_LIFETIME_PERCENT
	]
