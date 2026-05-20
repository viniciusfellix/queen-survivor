# Estrutura de Pastas

## Visão geral

```txt
res://
├── assets/
├── autoloads/
├── core/
├── data/
├── definitions/
├── gameplay/
├── runtime/
├── ui/
├── visual/
└── docs/
```

## `assets/`

Arquivos brutos do projeto.

Exemplos:

```txt
assets/spine/gaia/
assets/spine/goblin-warrior/
assets/placeholders/weapons/gaia_initial_weapon/
```

Não colocar lógica aqui.

## `autoloads/`

Singletons globais carregados pelo Godot.

Atuais:

```txt
GameEvents.gd
InputManager.gd
LocalizationManager.gd
SaveManager.gd
App.gd
```

## `core/constants/`

Constantes compartilhadas.

Atuais:

```txt
DamageTypes.gd
GameplayStateTypes.gd
UpgradeTypes.gd
```

## `data/`

Resources configuráveis do jogo.

Exemplos:

```txt
data/queens/queen_gaia.tres
data/enemies/enemy_chaser_basic.tres
data/weapons/weapon_gaia_initial.tres
data/weapons/components/gaia_initial_physical.tres
data/weapons/components/gaia_initial_magical.tres
data/drops/coin_default.tres
data/upgrades/
data/localization/pt_br.json
```

Esta é a área mais importante para Game Design.

## `definitions/`

Classes Resource usadas por arquivos `.tres`.

Exemplos:

```txt
QueenDefinition.gd
EnemyDefinition.gd
WeaponDefinition.gd
DamageComponentDefinition.gd
UpgradeDefinition.gd
CoinDropDefinition.gd
```

## `gameplay/`

Scenes/scripts que executam a lógica do jogo.

Exemplos:

```txt
gameplay/player/
gameplay/enemies/
gameplay/weapons/
gameplay/drops/
gameplay/run/
gameplay/spawners/
gameplay/test/
```

## `runtime/`

Estados temporários da run.

Exemplos:

```txt
RunState.gd
PlayerRuntimeState.gd
```

Esses dados morrem ao final da run.

## `ui/`

Interfaces.

Exemplos:

```txt
ui/debug/DebugOverlay.tscn
ui/level_up/LevelUpPanel.tscn
```

## `visual/`

Camada visual/animação.

Exemplos:

```txt
visual/characters/gaia/
visual/enemies/goblin_warrior/
visual/weapons/gaia_initial_weapon/
```

A pasta `visual/` não deve decidir dano, HP, XP, cooldown ou morte.
