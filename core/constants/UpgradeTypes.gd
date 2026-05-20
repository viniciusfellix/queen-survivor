extends RefCounted
class_name UpgradeTypes

const PLAYER_MOVE_SPEED_PERCENT: String = "player_move_speed_percent"
const PLAYER_MAX_HP_FLAT: String = "player_max_hp_flat"

const WEAPON_DAMAGE_FLAT: String = "weapon_damage_flat"
const WEAPON_COOLDOWN_PERCENT: String = "weapon_cooldown_percent"

static func is_player_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		PLAYER_MOVE_SPEED_PERCENT,
		PLAYER_MAX_HP_FLAT
	]

static func is_weapon_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		WEAPON_DAMAGE_FLAT,
		WEAPON_COOLDOWN_PERCENT
	]
