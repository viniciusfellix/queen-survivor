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
const WEAPON_HITBOX_RADIUS_FLAT: String = "weapon_hitbox_radius_flat"
const WEAPON_HITBOX_LIFETIME_PERCENT: String = "weapon_hitbox_lifetime_percent"

const COIN_MAGNET_RADIUS_PERCENT: String = "coin_magnet_radius_percent"
const COIN_COLLECT_RADIUS_PERCENT: String = "coin_collect_radius_percent"

static func is_player_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		PLAYER_MOVE_SPEED_PERCENT,
		PLAYER_MAX_HP_FLAT,
		PLAYER_DEFENSE_PERCENT,
		PLAYER_HEAL_FLAT,
		COIN_MAGNET_RADIUS_PERCENT,
		COIN_COLLECT_RADIUS_PERCENT
	]

static func is_weapon_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		WEAPON_DAMAGE_FLAT,
		WEAPON_COOLDOWN_PERCENT,
		WEAPON_PHYSICAL_DAMAGE_FLAT,
		WEAPON_MAGICAL_DAMAGE_FLAT,
		WEAPON_HITBOX_RADIUS_FLAT,
		WEAPON_HITBOX_LIFETIME_PERCENT
	]
