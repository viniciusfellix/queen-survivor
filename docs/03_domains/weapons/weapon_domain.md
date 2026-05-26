# Domínio — Armas

## Arma da Gaia

Ataque direcional pela mira, sem auto-target. A arma base contém components `physical:3` e `magical:3`, cooldown `2.0s` e hitbox retangular configurável.

## Geometria aprovada

```text
attack_area_gaia_initial_primary
shape: rectangle
size: (90,300)
local_offset: (0,0)
attack_hitbox_offset: 160
```

## Upgrades da arma

| Tipo | Efeito |
|---|---|
| `weapon_damage_flat` | aumenta todos os components |
| `weapon_physical_damage_flat` | aumenta physical |
| `weapon_magical_damage_flat` | aumenta magical |
| `weapon_cooldown_percent` | reduz cooldown |
| `weapon_hitbox_lifetime_percent` | amplia tempo ativo |
| `weapon_attack_area_scale_percent` | escala attack areas |

O upgrade antigo `weapon_hitbox_radius_flat` foi eliminado.
