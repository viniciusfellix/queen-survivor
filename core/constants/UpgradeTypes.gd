## Catálogo central dos tipos de upgrade disponíveis na run.
##
## Os ids definidos neste arquivo são utilizados pelos resources
## de upgrade e pelos controllers responsáveis por aplicar seus efeitos.
extends RefCounted
class_name UpgradeTypes

const PLAYER_MOVE_SPEED_PERCENT: String = "player_move_speed_percent"
const PLAYER_MAX_HP_FLAT: String = "player_max_hp_flat"
const PLAYER_DEFENSE_PERCENT: String = "player_defense_percent"
const PLAYER_HEAL_FLAT: String = "player_heal_flat"

const WEAPON_DAMAGE_FLAT: String = "weapon_damage_flat"
const WEAPON_COOLDOWN_PERCENT: String = "weapon_cooldown_percent"
const WEAPON_PHYSICAL_DAMAGE_FLAT: String = "weapon_physical_damage_flat"
const WEAPON_MAGICAL_DAMAGE_FLAT: String = "weapon_magical_damage_flat"

## Aumenta uniformemente as dimensões das áreas ofensivas da arma.
##
## Funciona para círculos, retângulos e quadrados sem assumir
## que toda hitbox possui raio.
const WEAPON_ATTACK_AREA_SCALE_PERCENT: String = "weapon_attack_area_scale_percent"

const WEAPON_HITBOX_LIFETIME_PERCENT: String = "weapon_hitbox_lifetime_percent"

const COIN_MAGNET_RADIUS_PERCENT: String = "coin_magnet_radius_percent"
const COIN_COLLECT_RADIUS_PERCENT: String = "coin_collect_radius_percent"

## Informa se um upgrade deve ser aplicado ao runtime da Queen.
static func is_player_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		PLAYER_MOVE_SPEED_PERCENT,
		PLAYER_MAX_HP_FLAT,
		PLAYER_DEFENSE_PERCENT,
		PLAYER_HEAL_FLAT,
		COIN_MAGNET_RADIUS_PERCENT,
		COIN_COLLECT_RADIUS_PERCENT
	]

## Informa se um upgrade deve ser aplicado à arma ativa.
static func is_weapon_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		WEAPON_DAMAGE_FLAT,
		WEAPON_COOLDOWN_PERCENT,
		WEAPON_PHYSICAL_DAMAGE_FLAT,
		WEAPON_MAGICAL_DAMAGE_FLAT,
		WEAPON_ATTACK_AREA_SCALE_PERCENT,
		WEAPON_HITBOX_LIFETIME_PERCENT
	]
