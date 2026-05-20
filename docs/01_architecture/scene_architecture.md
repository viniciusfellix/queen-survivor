# Arquitetura de Scenes

## Cena principal

```txt
Main.tscn
└── CurrentSceneRoot
```

`Main.gd` carrega a cena inicial:

```txt
res://gameplay/test/TestGaiaScene.tscn
```

## Cena de teste atual

```txt
TestGaiaScene : Node2D
├── ArenaRoot
│   └── TestArena
├── RuntimeRoot
│   ├── RunController
│   ├── DropController
│   ├── PlayerRoot
│   ├── EnemyRoot
│   ├── DropRoot
│   └── SpawnerRoot
│       └── EnemySpawner
├── PlayerSpawnPoint
├── Camera2D
├── DebugOverlay
└── LevelUpPanel
```

## Player

```txt
PlayerGaia : CharacterBody2D
├── CollisionShape2D
├── VisualRoot
│   └── GaiaVisual
└── WeaponRoot
    ├── AttackVisualRoot
    ├── AttackHitboxRoot
    └── GaiaInitialWeaponController
```

## Visual da Gaia

```txt
GaiaVisual : Node2D
├── SpineSprite
└── GaiaSpineAdapter
```

## Inimigo

```txt
EnemyBase : CharacterBody2D
├── CollisionShape2D
└── VisualRoot
    └── GoblinWarriorVisual
```

## Visual do Goblin

```txt
GoblinWarriorVisual : Node2D
├── SpineSprite
└── GoblinWarriorSpineAdapter
```

## Ataque visual da Gaia

```txt
GaiaAttackVisual : Node2D
├── PlaceholderRoot
│   └── Sprite2D
└── SpineRoot
```

## Hitbox do ataque

```txt
DirectionalAttackHitbox : Node2D
```

## Moeda

```txt
CoinDrop : Node2D
```

## Responsabilidades

### `TestGaiaScene`

Composição da cena de teste. Não deve conter regra final da run.

### `RunController`

Controla estado da run: XP, level, pause por level-up, moedas, kills.

### `DropController`

Cria drops físicos quando inimigos morrem.

### `EnemySpawner`

Cria inimigos em volta do player.

### `PlayerGaia`

Entidade viva do player.

### `GaiaVisual`

Visual da personagem.

### `GaiaInitialWeaponController`

Controla cooldown, direção, visual e hitbox da arma inicial.
