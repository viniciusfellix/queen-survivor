# Arquitetura — Cenas e Árvore Runtime

## Entrada

```text
Main.tscn
└── CurrentSceneRoot
    └── TestGaiaScene.tscn
```

`Main.gd` carrega a cena inicial. `TestGaiaScene.gd` monta o protótipo e conecta player, câmera e spawners.

## Cena técnica

```text
TestGaiaScene <Node2D>
├── ArenaRoot/TestArena
├── RuntimeRoot
│   ├── PlayerRoot/PlayerGaia [runtime]
│   ├── EnemyRoot/EnemyBase [runtime]
│   ├── DropRoot
│   ├── SpawnerRoot/EnemySpawner
│   ├── RunController
│   └── DropController
├── PlayerSpawnPoint
├── Camera2D
├── RunHud
├── RunFeedbackLayer
├── WorldFeedbackLayer
├── DebugOverlay
├── PrototypeToolsPanel
├── LevelUpPanel
└── ResultPanel
```

## PlayerGaia

```text
PlayerGaia <CharacterBody2D>
├── BodyCollision <CollisionShape2D>       # física
├── PlayerHurtbox <Area2D>                 # recebe ataque inimigo
│   └── RuntimeHurtboxShape_*              # criada em runtime
├── VisualRoot/GaiaVisual
└── WeaponRoot
    ├── AttackVisualRoot
    ├── AttackHitboxRoot
    └── GaiaInitialWeaponController
```

## EnemyBase / Goblin

```text
EnemyBase <CharacterBody2D>
├── BodyCollision <CollisionShape2D>       # física
├── Hurtbox <Area2D>                       # recebe arma Gaia
│   └── RuntimeHurtboxShape_*
├── ContactAttackHitbox <Area2D>           # ataca PlayerHurtbox
│   └── RuntimeEnemyAttackShape_*
└── VisualRoot/GoblinWarriorVisual
```

## Invariante

Nodes executam; resources configuram. Não guardar definição específica duplicada na cena genérica.
