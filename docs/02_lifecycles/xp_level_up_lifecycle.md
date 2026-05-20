# Lifecycle — XP e Level-up

## XP direta

```txt
EnemyBase.die()
↓
GameEvents.enemy_died(... xp_reward ...)
↓
RunController._on_enemy_died()
↓
RunState.add_xp()
```

Não existe drop físico de XP.

## Subida de nível

```txt
RunState.current_level_xp >= xp_required_for_next_level
↓
current_level aumenta
↓
pending_level_ups aumenta
↓
RunController inicia level-up
```

## Pause

```txt
RunController._start_next_level_up()
↓
run_state.is_paused = true
↓
get_tree().paused = true
↓
LevelUpPanel abre
```

## Escolha

```txt
LevelUpPanel botão
↓
GameEvents.run_level_up_option_selected
↓
RunController._on_level_up_option_selected
↓
PlayerController.apply_run_upgrade
↓
Run despausa
```

## Upgrades atuais

- Dano da arma +1.
- Cooldown da arma -10%.
- Velocidade da Gaia +10%.
- HP máximo +10 e cura +10.
