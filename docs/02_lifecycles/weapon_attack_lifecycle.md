# Lifecycle — Arma Inicial da Gaia

## Estado atual

A arma inicial da Gaia já possui:

- Cooldown.
- Direção por `aim_direction`.
- Visual placeholder por PNG.
- Hitbox direcional.
- Dano híbrido físico + mágico.
- Upgrades temporários de dano e cooldown.

## Fluxo

```txt
GaiaInitialWeaponController._process()
↓
cooldown chega em 0
↓
_resolve_attack_direction(runtime_state)
↓
_spawn_attack_visual()
↓
_spawn_attack_hitbox()
```

## Visual

```txt
GaiaAttackVisual
↓
PlaceholderRoot/Sprite2D
```

Depois poderá virar Spine:

```txt
GaiaAttackVisual
↓
SpineRoot/SpineSprite
```

## Hitbox

```txt
DirectionalAttackHitbox
↓
procura grupo "enemy"
↓
verifica distância
↓
envia DamagePayload
```

## Dano híbrido

`weapon_gaia_initial.tres` aponta para:

```txt
gaia_initial_physical.tres
gaia_initial_magical.tres
```

Cada componente tem:

- `damage_type`
- `amount`
- `affected_by_weakness`
- `affected_by_resistance`

## Upgrades

`GaiaInitialWeaponController.apply_run_upgrade()` aceita:

- `weapon_damage_flat`
- `weapon_cooldown_percent`
