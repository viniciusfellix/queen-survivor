# Domínio — Visual e Spine

## Regra principal

Visual não decide gameplay.

Spine só representa estado.

## Gaia

Arquivos:

```txt
visual/characters/gaia/GaiaVisual.tscn
visual/characters/gaia/GaiaVisualController.gd
visual/characters/gaia/GaiaSpineAdapter.gd
assets/spine/gaia/
```

## Goblin

Arquivos:

```txt
visual/enemies/goblin_warrior/GoblinWarriorVisual.tscn
visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd
visual/enemies/goblin_warrior/GoblinWarriorSpineAdapter.gd
assets/spine/goblin-warrior/
```

## Ataque da Gaia

Atual placeholder:

```txt
visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn
assets/placeholders/weapons/gaia_initial_weapon/gaia_attack_placeholder.png
```

Futuro Spine:

```txt
assets/spine/weapons/gaia_initial_weapon/
visual/weapons/gaia_initial_weapon/GaiaAttackSpineAdapter.gd
```

## Quando trocar placeholder por Spine

Não mexer no `GaiaInitialWeaponController`.

Trocar apenas `GaiaAttackVisual.tscn` e o controller visual/adapters.
