# Lifecycle — Visual Spine

## Princípio

Spine representa visualmente o estado da gameplay. Spine não controla gameplay.

## Gaia

```txt
PlayerRuntimeState
↓
GaiaVisualController.apply_runtime_state()
↓
GaiaSpineAdapter.play_animation()
↓
SpineSprite
```

## Goblin

```txt
EnemyBase
↓
GoblinWarriorVisualController.apply_enemy_runtime_state()
↓
GoblinWarriorSpineAdapter.play_animation()
↓
SpineSprite
```

## Ataque da Gaia

Atualmente usa PNG placeholder.

Futuro:

```txt
GaiaAttackVisualController
↓
GaiaAttackSpineAdapter
↓
SpineSprite
```

## Onde configurar animações

### Gaia

`GaiaVisual.tscn`

- `idle_animation_name = Idle1_Pose2`
- `run_animation_name = Run1_Pose3`
- `death_animation_name = Die_Pose1`

### Goblin

`GoblinWarriorVisual.tscn`

- `idle_animation_name = Idle`
- `run_animation_name = Run`
- `death_animation_name = Die`
