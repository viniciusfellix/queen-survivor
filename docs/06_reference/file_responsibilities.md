# File Responsibilities

Consulta rapida para localizar scripts e ownership principal no projeto.

## Core e servicos globais

| Arquivo | Responsabilidades |
|---|---|
| `App.gd` | boot, versao, locale inicial e dados gerais da aplicacao |
| `GameEvents.gd` | event bus global |
| `InputManager.gd` | leitura central de input de movimento e mira |
| `PoolManager.gd` | pooling central de objetos de alta rotacao |
| `SaveManager.gd` | save, load, reset e persistencia |
| `DeveloperLogChannels.gd` | nomes/canais de log |
| `DeveloperAuditLogger.gd` | logger filtrado para desenvolvimento |

## Definitions

| Arquivo | Responsabilidades |
|---|---|
| `QueenDefinition.gd` | dados base da Gaia |
| `EnemyDefinition.gd` | atributos, recompensas, hurtboxes e ataque de contato de inimigos |
| `WeaponDefinition.gd` | dados da arma, dano, cooldown e attack areas |
| `CombatShapeDefinition.gd` | shape/offset/rotacao runtime |
| `AttackAreaDefinition.gd` | regiao ofensiva |
| `HurtboxAreaDefinition.gd` | regiao vulneravel |
| `EnemyAttackDefinition.gd` | dano/timing/shape do ataque inimigo |
| `DamageComponentDefinition.gd` | componente adicional de dano |
| `UpgradeDefinition.gd` | upgrade individual |
| `UpgradePoolDefinition.gd` | regras de oferta e repeticao de upgrades |
| `MapDefinition.gd` | duracao, reward e referencia de spawn timeline |
| `SpawnTimelineDefinition.gd` | colecao de waves/entries |
| `SpawnTimelineEntryDefinition.gd` | configuracao de uma wave |
| `SpawnRuleDefinition.gd` | regra individual de spawn dentro da wave |
| `CoinDropDefinition.gd` | configuracao de moeda, coleta e magnetismo |

## Gameplay e combate

| Arquivo | Responsabilidades |
|---|---|
| `DamagePayload.gd` | mensagem de dano e metadados da fonte |
| `DamageResolver.gd` | regra matematica de dano |
| `DamageTypes.gd` | tipos de dano validos |
| `GameplayStateTypes.gd` | estados logicos de gameplay |
| `HurtboxComponent.gd` | construcao/configuracao de hurtboxes |
| `DirectionalAttackHitbox.gd` | hitbox temporaria do ataque da Gaia |
| `EnemyAttackHitbox.gd` | hitbox ofensiva do inimigo contra a Gaia |
| `PlayerController.gd` | Gaia: input, movimento, dano, dash e estado principal |
| `PlayerRuntimeState.gd` | estado mutavel da Gaia em runtime |
| `EnemyBase.gd` | perseguicao, dano recebido, morte, pooling e comunicacao visual de inimigos |
| `GaiaInitialWeaponController.gd` | cooldown, spawn da hitbox e upgrades da arma inicial |
| `EnemySpawner.gd` | Spawn Timeline V2, rules, pooling e contadores de inimigo |
| `DropController.gd` | drops e spawn de moedas |
| `CoinDrop.gd` | moeda pooled com magnetismo/coleta por `Area2D` |
| `RunState.gd` | estado central da run |
| `RunQuery.gd` | consultas utilitarias sobre a run |
| `RunController.gd` | orquestracao da run, level-up, vitoria, derrota e resultado |
| `RewardResolver.gd` | recompensa monetaria final |
| `LevelUpOptionService.gd` | selecao de opcoes validas de upgrade |

## Visual

| Arquivo | Responsabilidades |
|---|---|
| `SpineAnimationAdapterBase.gd` | integracao base com Spine |
| `SpineVisualControllerBase.gd` | helpers visuais comuns de Spine |
| `GaiaSpineAdapter.gd` | adapter Spine da Gaia |
| `GaiaVisualController.gd` | animacao, blink e feedback visual da Gaia |
| `GoblinWarriorSpineAdapter.gd` | adapter Spine do Goblin |
| `GoblinWarriorVisualController.gd` | animacoes e feedback visual do Goblin |
| `GaiaAttackVisualController.gd` | visual temporario do ataque da Gaia |

## UI e debug

| Arquivo | Responsabilidades |
|---|---|
| `RunHud.gd` | HUD principal da run |
| `LevelUpPanel.gd` | selecao e exibicao de upgrades |
| `ResultPanel.gd` | resultado final e status de save |
| `RunFeedbackLayer.gd` | feedback textual de run |
| `WorldFeedbackLayer.gd` | feedbacks ancorados no mundo |
| `FloatingCombatText.gd` | texto flutuante pooled |
| `DebugOverlay.gd` | overlay tecnico |
| `PrototypeToolsPanel.gd` | painel tecnico F3 |
| `RuntimeTreeSnapshot.gd` | snapshot tecnico de arvore runtime |
| `StressMetricsOverlay.gd` | overlay tecnico exclusivo da stress scene |

## Cenas e infraestrutura

| Arquivo | Responsabilidades |
|---|---|
| `Main.gd` | carregar a cena inicial oficial |
| `RunScene.gd` | composition root oficial da run |
| `TestGaiaScene.gd` | legado tecnico da composicao anterior |
| `StressRunScene.gd` | composition root tecnica para stress/profiling |
| `TestArena.gd` | grid tecnico da arena |
| `FollowCamera.gd` | camera seguindo o player |
