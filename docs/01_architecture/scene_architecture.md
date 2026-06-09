# Arquitetura - Cenas e Arvore Runtime

> Documento legado de apoio. A source of truth atual de arquitetura esta em `docs/01_architecture/ARCHITECTURE_OVERVIEW.md`.

## Entrada

```text
Main.tscn
-> CurrentSceneRoot
   -> RunScene.tscn
```

`Main.gd` carrega a cena inicial. `RunScene.gd` e a composition root oficial atual da run.

## Cena oficial da run

```text
RunScene <Node2D>
|- ArenaRoot/TestArena
|- RuntimeRoot
|  |- PlayerRoot/PlayerGaia [runtime]
|  |- EnemyRoot/EnemyBase [runtime]
|  |- DropRoot
|  |- SpawnerRoot/EnemySpawner
|  |- RunController
|  `- DropController
|- PlayerSpawnPoint
|- Camera2D
|- RunHud
|- RunFeedbackLayer
|- WorldFeedbackLayer
|- DebugRoot
|  |- DebugOverlay
|  `- PrototypeToolsPanel
|- LevelUpPanel
`- ResultPanel
```

## Estado atual

- `RunScene` e a source of truth oficial da run.
- `TestGaiaScene` continua no projeto apenas como referencia tecnica temporaria.
- `DebugRoot` existe para organizar ferramentas tecnicas e dev-only sem mistura com a UI principal de jogo.

## PlayerGaia

```text
PlayerGaia <CharacterBody2D>
|- BodyCollision <CollisionShape2D>       # fisica
|- PlayerHurtbox <Area2D>                 # recebe ataque inimigo
|  `- RuntimeHurtboxShape_*
|- VisualRoot/GaiaVisual
`- WeaponRoot
   |- AttackVisualRoot
   |- AttackHitboxRoot
   `- GaiaInitialWeaponController
```

## EnemyBase / Goblin

```text
EnemyBase <CharacterBody2D>
|- BodyCollision <CollisionShape2D>       # fisica
|- Hurtbox <Area2D>                       # recebe arma da Gaia
|  `- RuntimeHurtboxShape_*
|- ContactAttackHitbox <Area2D>           # ataca PlayerHurtbox
|  `- RuntimeEnemyAttackShape_*
`- VisualRoot/GoblinWarriorVisual
```

## Invariantes

- Nodes executam; resources configuram.
- `BodyCollision`, `Hitbox` e `Hurtbox` sao responsabilidades separadas.
- `DebugRoot` nao participa de gameplay.
- `DamageResolver` calcula dano; nao detecta colisao.
