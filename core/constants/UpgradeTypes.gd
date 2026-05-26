## Catálogo central dos tipos de upgrade disponíveis na run.
##
## Os ids definidos neste arquivo são utilizados pelos resources
## de upgrade e pelos controllers responsáveis por aplicar seus efeitos.
##
## Manter os ids centralizados evita strings divergentes espalhadas
## entre resources, RunController, PlayerController e armas.
extends RefCounted
class_name UpgradeTypes

## Aumenta percentualmente a velocidade de movimento da Queen.
const PLAYER_MOVE_SPEED_PERCENT: String = "player_move_speed_percent"

## Aumenta o HP máximo da Queen em valor fixo.
const PLAYER_MAX_HP_FLAT: String = "player_max_hp_flat"

## Aumenta percentualmente a defesa da Queen.
const PLAYER_DEFENSE_PERCENT: String = "player_defense_percent"

## Recupera imediatamente HP da Queen em valor fixo.
const PLAYER_HEAL_FLAT: String = "player_heal_flat"

## Aumenta o dano geral da arma atual.
##
## Regra detalhada sobre sua interação com componentes físicos
## e mágicos será consolidada futuramente com o designer.
const WEAPON_DAMAGE_FLAT: String = "weapon_damage_flat"

## Reduz percentualmente o cooldown da arma atual.
const WEAPON_COOLDOWN_PERCENT: String = "weapon_cooldown_percent"

## Aumenta apenas o componente físico da arma atual.
const WEAPON_PHYSICAL_DAMAGE_FLAT: String = "weapon_physical_damage_flat"

## Aumenta apenas o componente mágico da arma atual.
const WEAPON_MAGICAL_DAMAGE_FLAT: String = "weapon_magical_damage_flat"

## Aumenta o raio da hitbox da arma atual.
const WEAPON_HITBOX_RADIUS_FLAT: String = "weapon_hitbox_radius_flat"

## Aumenta percentualmente o tempo ativo da hitbox da arma atual.
const WEAPON_HITBOX_LIFETIME_PERCENT: String = "weapon_hitbox_lifetime_percent"

## Aumenta percentualmente a distância de magnetismo das moedas.
const COIN_MAGNET_RADIUS_PERCENT: String = "coin_magnet_radius_percent"

## Aumenta percentualmente o raio de coleta final das moedas.
const COIN_COLLECT_RADIUS_PERCENT: String = "coin_collect_radius_percent"

## Informa se um tipo de upgrade deve ser aplicado ao runtime da Queen.
##
## Inclui também propriedades relacionadas à coleta de moeda,
## pois atualmente seus multiplicadores pertencem ao PlayerRuntimeState.
static func is_player_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		PLAYER_MOVE_SPEED_PERCENT,
		PLAYER_MAX_HP_FLAT,
		PLAYER_DEFENSE_PERCENT,
		PLAYER_HEAL_FLAT,
		COIN_MAGNET_RADIUS_PERCENT,
		COIN_COLLECT_RADIUS_PERCENT
	]

## Informa se um tipo de upgrade deve ser aplicado à arma ativa.
static func is_weapon_upgrade(upgrade_type: String) -> bool:
	return upgrade_type in [
		WEAPON_DAMAGE_FLAT,
		WEAPON_COOLDOWN_PERCENT,
		WEAPON_PHYSICAL_DAMAGE_FLAT,
		WEAPON_MAGICAL_DAMAGE_FLAT,
		WEAPON_HITBOX_RADIUS_FLAT,
		WEAPON_HITBOX_LIFETIME_PERCENT
	]
