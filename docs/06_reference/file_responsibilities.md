# Responsabilidades dos Arquivos — Consulta Rápida

Use busca textual por termos como `visual`, `Gaia`, `ataque`, `hurtbox`, `upgrade`, `save`, `spawn` ou `debug`.

## Core e serviços globais

| Arquivo | Responsabilidades |
|---|---|
| `App.gd` | título, versão e boot |
| `GameEvents.gd` | Event Bus global |
| `LocalizationManager.gd` | localization JSON/get_text |
| `InputManager.gd` | movimento/mira/última direção |
| `SaveManager.gd` | save, resultado e reset |
| `DeveloperLogChannels.gd` | nomes de canais |
| `DeveloperAuditLogger.gd` | logs filtrados/buffer |

## Definitions

| Arquivo | Responsabilidades |
|---|---|
| `QueenDefinition.gd` | atributos, equipamento e hurtboxes da Queen |
| `EnemyDefinition.gd` | atributos, recompensas, hurtboxes, ataque de contato, esbarrão corporal e knockback recebido.
| `WeaponDefinition.gd` | dados da arma, áreas ofensivas, dano e efeitos pós-hit como knockback. |
| `CombatShapeDefinition.gd` | shape/offset/rotação runtime |
| `AttackAreaDefinition.gd` | região ofensiva |
| `HurtboxAreaDefinition.gd` | região vulnerável |
| `EnemyAttackDefinition.gd` | dano/timing/shape do ataque inimigo |
| `DamageComponentDefinition.gd` | componente de dano |
| `UpgradeDefinition.gd` | uma melhoria |
| `UpgradePoolDefinition.gd` | pool/repetições/stacks |
| `MapDefinition.gd` | duração/reward/spawn/pool |
| `SpawnTimelineDefinition.gd` | entries por tempo |
| `SpawnTimelineEntryDefinition.gd` | parâmetros de uma wave |
| `CoinDropDefinition.gd` | magnetismo/coleta/valor |

## Gameplay e combate

| Arquivo | Responsabilidades |
|---|---|
| `DamagePayload.gd` | mensagem de dano e fonte |
| `DamageResolver.gd` | defesa/fraqueza/resistência |
| `DamageTypes.gd` | tipos válidos |
| `GameplayStateTypes.gd` | estados lógicos |
| `HurtboxComponent.gd` | construir hurtboxes e expor receiver |
| `DirectionalAttackHitbox.gd` | Detecta EnemyHurtbox, envia DamagePayload e solicita knockback pós-hit quando configurado. |
| `EnemyAttackHitbox.gd` | atacar PlayerHurtbox pelo inimigo |
| `PlayerController.gd` | Gaia: input, dano, upgrades, morte, hurtbox |
| `PlayerRuntimeState.gd` | estado mutável da Gaia |
| `EnemyBase.gd` | perseguição direta, velocidades externas temporárias, esbarrão físico, knockback recebido, dano, morte e comunicação visual.
| `GaiaInitialWeaponController.gd` | disparo/cooldown/upgrades arma |
| `EnemySpawner.gd` | waves/instâncias |
| `DropController.gd` | chance/criação de coin drop |
| `CoinDrop.gd` | moeda runtime |
| `RunState.gd` | estado da run |
| `RunQuery.gd` | bloqueio de gameplay |
| `RunController.gd` | orquestração/resultado |
| `RewardResolver.gd` | reward monetário |
| `LevelUpOptionService.gd` | opções válidas de upgrade |

## Visual

| Arquivo | Responsabilidades |
|---|---|
| `SpineAnimationAdapterBase.gd` | Centraliza comunicação com Spine, incluindo execução em tracks específicas e limpeza de track |
| `SpineVisualControllerBase.gd` | Fornece helpers para animação base e overlays em tracks superiores |
| `GaiaSpineAdapter.gd` | adapter Gaia |
| `GaiaVisualController.gd` | Controla animações visuais da Gaia, flash de dano e blink overlay |
| `GoblinWarriorSpineAdapter.gd` | adapter Goblin |
| `GoblinWarriorVisualController.gd` | animações e flash claro |
| `GaiaAttackVisualController.gd` | visual/fade/rotação do ataque |

## UI e debug

| Arquivo | Responsabilidades |
|---|---|
| `RunHud.gd` | barras e métricas |
| `LevelUpPanel.gd` | cards, ícones, badges, seleção |
| `ResultPanel.gd` | resultado/status save |
| `RunFeedbackLayer.gd` | mensagens textuais |
| `WorldFeedbackLayer.gd` | posicionar feedback no mundo |
| `FloatingCombatText.gd` | animação do número de dano |
| `DebugOverlay.gd` | dados técnicos/linhas Gaia-inimigos |
| `PrototypeToolsPanel.gd` | F3/F4/force result/reset |
| `RuntimeTreeSnapshot.gd` | snapshot compactado |

## Cenas e infraestrutura

| Arquivo | Responsabilidades |
|---|---|
| `Main.gd` | carregar cena inicial |
| `TestGaiaScene.gd` | montar protótipo/configurar ligações |
| `TestArena.gd` | grid técnico |
| `FollowCamera.gd` | câmera seguindo player |
