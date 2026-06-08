# Arquitetura — Cenas e Árvore Runtime

## Entrada

```text
Main.tscn
└── CurrentSceneRoot
    └── RunScene.tscn
```

`Main.gd` carrega a cena inicial. `RunScene.gd` é a composition root oficial atual e conecta player, câmera e spawners.

## Cena oficial da run

```text
RunScene <Node2D>
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
├── DebugRoot
│   ├── DebugOverlay
│   └── PrototypeToolsPanel
├── LevelUpPanel
└── ResultPanel
```

`TestGaiaScene` continua existindo como cena técnica legada/de referência temporária.

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
