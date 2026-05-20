# Domínio — XP e Level-up

## Arquivos principais

```txt
runtime/RunState.gd
gameplay/run/RunController.gd
gameplay/level_up/LevelUpOptionService.gd
ui/level_up/LevelUpPanel.tscn
ui/level_up/LevelUpPanel.gd
definitions/UpgradeDefinition.gd
data/upgrades/
```

## XP

XP entra diretamente quando inimigo morre.

Não existe:

- Orbe de XP.
- Magnetismo de XP.
- Coleta física de XP.

## Level-up atual

Quando XP suficiente é atingida:

```txt
RunController pausa a run
LevelUpPanel mostra 3 opções
Jogador escolhe
Upgrade aplica
Run continua
```

## Pool de upgrades

Atual:

```txt
upgrade_weapon_damage_flat.tres
upgrade_weapon_cooldown_percent.tres
upgrade_player_move_speed_percent.tres
upgrade_player_max_hp_flat.tres
```

## Rolls e Blocks

Não implementados nesta fase.

Arquitetura permite adicionar depois.
