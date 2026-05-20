# Event Bus — GameEvents

`GameEvents.gd` é um autoload usado para comunicação entre sistemas.

## Por que usar

Evita que sistemas fiquem buscando uns aos outros diretamente.

Exemplo correto:

```txt
EnemyBase morre
↓
emite GameEvents.enemy_died
↓
RunController ganha XP
↓
DropController cria moeda física
```

O `EnemyBase` não precisa conhecer `RunController` nem `DropController`.

## Principais eventos atuais

### Player

```gdscript
player_damaged(raw_damage, final_damage, current_hp, max_hp, source_id)
player_died(source_id)
player_state_changed(previous_state, new_state)
```

### Enemy

```gdscript
enemy_damaged(enemy_id, raw_damage, final_damage, current_hp, max_hp, source_id)
enemy_died(enemy_id, source_id, xp_reward, global_position, coin_drop_chance, coin_drop_value)
```

### Run

```gdscript
run_xp_changed(run_xp_gained, current_level, current_level_xp, xp_required_for_next_level)
run_enemy_killed(enemy_id, enemies_killed)
run_coin_collected(value, global_position)
run_coins_changed(run_coins_collected, run_coins_available)
```

### Level-up

```gdscript
run_level_up_started(current_level, options)
run_level_up_option_selected(upgrade)
run_level_up_completed(current_level, selected_upgrade_id)
```

### Spine

```gdscript
spine_animation_requested(animation_name)
spine_animation_changed(animation_name)
```

## Cuidado

Ao alterar assinatura de um signal, é obrigatório atualizar todos os listeners.

Exemplo:

Quando `enemy_died` ganhou parâmetros de moeda, foi preciso atualizar:

- `RunController._on_enemy_died`
- `DropController._on_enemy_died`
- `EnemyBase.die`
