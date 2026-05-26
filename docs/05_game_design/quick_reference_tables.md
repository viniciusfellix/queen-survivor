# Referência Rápida de Balanceamento

## Valores validados

| Conteúdo | Valor |
|---|---|
| Duração mapa | 600s |
| Level-up inicial | 3 opções |
| Gaia HP base | 100 |
| Arma Gaia | cooldown 2.0; physical 3 + magical 3 |
| Shape Gaia ataque | rectangle `(90,300)`; offset de origem `160` |
| Goblin ataque | physical 6; intervalo 1.0; delay 0.75 |
| Goblin fraqueza | physical/magical +50% |
| Gaia invencibilidade | 0.5s |

## Layers

| # | Uso |
|---:|---|
| 1 | World |
| 2 | PlayerBody |
| 3 | EnemyBody |
| 4 | PlayerAttackHitbox |
| 5 | EnemyHurtbox |
| 6 | EnemyAttackHitbox |
| 7 | PlayerHurtbox |
| 8 | DropPickup |

## Upgrades suportados relevantes

| Tipo | Valor |
|---|---|
| `player_move_speed_percent` | float |
| `player_max_hp_flat` | int |
| `player_defense_percent` | float |
| `player_heal_flat` | int |
| `weapon_damage_flat` | int |
| `weapon_cooldown_percent` | float |
| `weapon_physical_damage_flat` | int |
| `weapon_magical_damage_flat` | int |
| `weapon_hitbox_lifetime_percent` | float |
| `weapon_attack_area_scale_percent` | float |
| `coin_magnet_radius_percent` | float |
| `coin_collect_radius_percent` | float |
