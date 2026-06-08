# AUDIT 03 - System Classification

## Legenda

- `MANTER`
- `MANTER COM AJUSTES`
- `REFAZER USANDO GODOT NATIVO`
- `DESCARTAR`
- `ADIAR`

Prioridade:

- `P0` crítica
- `P1` alta
- `P2` média
- `P3` baixa

## 1. Estrutura e boot

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| Cena raiz `Main` | `MANTER COM AJUSTES` | P1 | Root mínima é correta | Carrega cena técnica como cena oficial | Manter `Main`, trocar a cena inicial para uma cena de jogo/composition root clara | `scenes/Main.tscn`, `scenes/Main.gd`, `gameplay/test/TestGaiaScene.tscn` |
| `TestGaiaScene` como core do jogo | `MANTER COM AJUSTES` | P0 | Hoje é o composition root real | Mistura teste, runtime, UI e debug | Promover para cena principal real ou substituí-la por `RunScene`/`GameScene` equivalente | `gameplay/test/TestGaiaScene.tscn`, `gameplay/test/TestGaiaScene.gd` |
| Arquivos `.tmp` versionados | `DESCARTAR` | P1 | Não fazem parte do produto | Confusão e risco de editar o arquivo errado | Remover em fase de limpeza | `gameplay/test/*.tmp`, `gameplay/player/*.tmp` |

## 2. Autoloads

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `GameEvents` | `MANTER COM AJUSTES` | P1 | Event bus global ajuda UI/save/debug | Ficar grande demais e virar dependência universal | Reduzir para eventos realmente globais | `autoloads/GameEvents.gd` |
| `PoolManager` | `MANTER` | P1 | Survivors se beneficiam muito de pooling | Nenhum grave; só API pode ser simplificada depois | Preservar como infraestrutura central | `autoloads/PoolManager.gd` |
| `SaveManager` | `MANTER COM AJUSTES` | P1 | Bom ponto único de persistência | JSON manual e schema drift | Manter autoload; migrar backend de serialização | `autoloads/SaveManager.gd`, `runtime/SaveData.gd` |
| `DeveloperAuditLogger` | `MANTER COM AJUSTES` | P2 | Útil em desenvolvimento | Vazamento em release, custo de formatação/log | Manter só em builds/debug path | `autoloads/DeveloperAuditLogger.gd` |
| `App` | `MANTER COM AJUSTES` | P3 | Pode seguir como bootstrap leve | Hardcode de locale e duplicação de config | Enxugar para bootstrap mínimo | `autoloads/App.gd` |
| `InputManager` | `REFAZER USANDO GODOT NATIVO` | P1 | Para 1 player local, a Godot resolve mais simples | Acoplamento temporal global | Ler input direto no `PlayerController`; manter manager só se surgir necessidade real | `autoloads/InputManager.gd`, `gameplay/player/PlayerController.gd` |

## 3. Resources e data-driven

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `WeaponDefinition` | `MANTER` | P1 | Resource adequada e útil | Source of truth ainda confuso | Consolidar como autoridade única da arma | `definitions/WeaponDefinition.gd`, `data/weapons/weapon_gaia_initial.tres` |
| `QueenDefinition` | `MANTER` | P1 | Modela bem a queen jogável | Algumas configs acabam duplicadas em cena | Preservar e limpar sobreposição com cena | `definitions/QueenDefinition.gd`, `data/queens/queen_gaia.tres` |
| `EnemyDefinition` | `MANTER` | P1 | Bom eixo para data-driven de inimigos | Validação ainda fraca | Manter e fortalecer validadores/ranges | `definitions/EnemyDefinition.gd`, `data/enemies/enemy_chaser_basic.tres` |
| `MapDefinition` | `MANTER` | P1 | Simples e correto | Nenhum grave | Manter | `definitions/MapDefinition.gd`, `data/maps/map_test_arena_10min.tres` |
| `UpgradeDefinition` | `MANTER COM AJUSTES` | P1 | Bom formato para conteúdo | Tipos e aplicação ainda dispersos | Manter definição; centralizar aplicação | `definitions/UpgradeDefinition.gd`, `data/upgrades/*.tres` |
| `UpgradePoolDefinition` | `MANTER` | P1 | Pool data-driven faz sentido | Nenhum grave | Manter | `definitions/UpgradePoolDefinition.gd`, `data/upgrade_pools/*.tres` |
| `AttackAreaDefinition` / `HurtboxAreaDefinition` | `MANTER COM AJUSTES` | P1 | Contrato é bom | Excesso de uso dinâmico em casos simples | Manter contrato, simplificar runtime onde possível | `definitions/AttackAreaDefinition.gd`, `definitions/HurtboxAreaDefinition.gd` |
| `DamageComponentDefinition` | `MANTER` | P2 | Útil para dano composto/híbrido | Overkill em ataques triviais, mas válido | Preservar | `definitions/DamageComponentDefinition.gd` |
| Attack area duplicada da Gaia | `DESCARTAR` | P1 | Duplicidade de fonte | Configuração divergente | Escolher uma fonte única | `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`, `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres` |

## 4. Combate

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| Contrato hitbox/hurtbox/body collision | `MANTER` | P0 | Arquitetura conceitualmente correta | Regressão se simplificar errado | Preservar como contrato formal | `gameplay/combat/*`, `gameplay/player/PlayerGaia.tscn`, `gameplay/enemies/EnemyBase.tscn` |
| `DamagePayload` | `MANTER` | P1 | Bom DTO de dano | Nenhum grave | Preservar | `gameplay/combat/DamagePayload.gd` |
| `DamageResolver` | `MANTER` | P1 | Regra central bem separada | Pode ganhar fast paths | Preservar com otimizações leves | `gameplay/combat/DamageResolver.gd` |
| `HurtboxComponent` | `MANTER COM AJUSTES` | P1 | Componente genérico faz sentido | Runtime building para tudo pode pesar/manter complexidade | Manter conceito; simplificar quando shape for estática | `gameplay/combat/HurtboxComponent.gd` |
| `DirectionalAttackHitbox` | `MANTER COM AJUSTES` | P1 | Atende arma melee/direcional | Duplica lógica com dash/enemy attack | Preservar ideia; consolidar infraestrutura de hitbox | `gameplay/weapons/attacks/DirectionalAttackHitbox.gd` |
| `EnemyAttackHitbox` | `MANTER COM AJUSTES` | P1 | Dano inimigo separado da colisão física é correto | Similaridade excessiva com outras hitboxes | Manter função, simplificar pipeline | `gameplay/combat/EnemyAttackHitbox.gd` |
| `PlayerDashImpactArea` | `MANTER COM AJUSTES` | P1 | Dash ofensivo separado é correto | Duplica bastante com ataque ativo | Reusar infraestrutura comum de hitbox ofensiva | `gameplay/player/PlayerDashImpactArea.gd` |

## 5. Player / Gaia

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `PlayerController` | `MANTER COM AJUSTES` | P0 | Núcleo funcional e reaproveitável | Grande demais, acoplado demais | Fatiar sem quebrar comportamento | `gameplay/player/PlayerController.gd` |
| `PlayerRuntimeState` | `MANTER COM AJUSTES` | P2 | Ajuda a separar estado de save | Carrega dados que podem ficar no controller | Enxugar para stats/estado útil de runtime | `runtime/PlayerRuntimeState.gd` |
| `PlayerGaia.tscn` | `MANTER COM AJUSTES` | P1 | Cena-base do player é boa | Export duplicado versus `WeaponDefinition` | Limpar exports redundantes | `gameplay/player/PlayerGaia.tscn` |
| Dash como feature | `MANTER COM AJUSTES` | P1 | Funciona e enriquece o jogo | Muitas políticas misturadas num fluxo só | Extrair subcomponente local futuramente | `gameplay/player/PlayerController.gd`, `definitions/QueenDashDefinition.gd`, `gameplay/player/PlayerDashImpactArea.gd` |

## 6. Arma da Gaia

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `GaiaInitialWeaponController` | `MANTER COM AJUSTES` | P0 | Já encapsula a arma principal | Grande, mistura cooldown, spawn, upgrade e source of truth | Preservar intenção; separar config, spawn e upgrade apply | `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` |
| `GaiaAttackVisualController` | `MANTER COM AJUSTES` | P2 | Visual de ataque é simples e correto | Placeholder + Spine futuro numa camada só | Manter; simplificar resolução/caminhos | `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd` |

## 7. Inimigos e spawn

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `EnemyBase` | `MANTER COM AJUSTES` | P0 | Núcleo funcional e importante | 813 linhas, muita responsabilidade | Fatiar em movimento/combat/reward ao longo das fases | `gameplay/enemies/EnemyBase.gd` |
| `EnemySpawner` | `MANTER COM AJUSTES` | P1 | Timeline + pooling faz sentido em survivor | Amarrado à cena técnica e grupos | Manter; reduzir resolução implícita e dependência de scene shape atual | `gameplay/spawners/EnemySpawner.gd`, `gameplay/spawners/EnemySpawner.tscn` |
| Goblin atual | `MANTER` | P2 | Bom inimigo-base do protótipo | Nenhum grave | Preservar como benchmark de regressão | `data/enemies/enemy_chaser_basic.tres`, `visual/enemies/goblin_warrior/*` |
| Body bump / slide / knockback | `MANTER COM AJUSTES` | P1 | Necessários para feel de horda | Complexidade excessiva no `EnemyBase` | Preservar mecânica, simplificar implementação | `gameplay/enemies/EnemyBase.gd` |

## 8. Drops e moedas

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `DropController` | `MANTER COM AJUSTES` | P1 | Escuta morte e instancia drop corretamente | Resolução por grupo/root implícita | Manter função; simplificar wiring | `gameplay/drops/DropController.gd` |
| `CoinDrop` | `REFAZER USANDO GODOT NATIVO` | P1 | Ideia está certa, mas fluxo pode ser mais idiomático com `Area2D` dedicadas | Magnetismo e coleta ficam mais complexos do que precisam | Reestruturar moeda em torno de áreas de magnetismo/coleta | `gameplay/drops/CoinDrop.gd`, `gameplay/drops/CoinDrop.tscn`, `definitions/CoinDropDefinition.gd` |
| `CoinDropDefinition` | `MANTER` | P2 | Data-driven adequado | Nenhum grave | Preservar | `definitions/CoinDropDefinition.gd`, `data/drops/coin_default.tres` |

## 9. XP, level-up e upgrades

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `LevelUpOptionService` | `MANTER` | P1 | Serviço puro, bem separado | Nenhum grave | Preservar | `gameplay/level_up/LevelUpOptionService.gd` |
| Aplicação de upgrades | `REFAZER USANDO GODOT NATIVO` | P0 | Hoje está espalhada entre run/player/weapon | Crescimento futuro vai piorar rápido | Centralizar roteamento de aplicação | `gameplay/run/RunController.gd`, `gameplay/player/PlayerController.gd`, `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` |
| `LevelUpPanel` | `MANTER COM AJUSTES` | P2 | Faz só UI, o que é bom | Implementação muito hardcoded para 3 cards | Manter; tornar mais data-driven e menos reflexiva | `ui/level_up/LevelUpPanel.gd`, `ui/level_up/LevelUpPanel.tscn` |

## 10. Run, resultado e save

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `RunController` | `MANTER COM AJUSTES` | P0 | Centraliza a run e funciona | Grande demais | Fatiar: progressão, resultado, upgrade apply/debug | `gameplay/run/RunController.gd` |
| `RunState` | `MANTER COM AJUSTES` | P2 | Distingue run de save | Pode ficar mais enxuto e menos “quase-save” | Preservar com limpeza de responsabilidades | `runtime/RunState.gd` |
| `RunResultPayload` | `MANTER` | P2 | DTO claro | Nenhum grave | Preservar | `gameplay/run/RunResultPayload.gd` |
| `RewardResolver` | `MANTER` | P2 | Serviço puro simples e correto | Nenhum grave | Preservar | `gameplay/run/RewardResolver.gd` |
| `SaveData` | `MANTER COM AJUSTES` | P1 | Conteúdo do save é adequado para a fase | Serialização manual e campos sem export nativo | Preservar schema geral, mudar backend de persistência | `runtime/SaveData.gd` |
| Persistência JSON manual | `MANTER COM AJUSTES` | P2 | Aceitável no protótipo | Drift e manutenção manual | Migrar para save nativo de `Resource` quando estabilizar baseline | `autoloads/SaveManager.gd`, `runtime/SaveData.gd` |
| `ResultPanel` | `MANTER` | P2 | UI passiva e correta | Nenhum grave | Preservar | `ui/result/ResultPanel.gd`, `ui/result/ResultPanel.tscn` |

## 11. UI e feedback

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `RunHud` | `MANTER COM AJUSTES` | P1 | HUD necessária e bem separada conceitualmente | Polling + dependência de `get_debug_data()` | Atualizar por sinais/payloads reais de gameplay | `ui/hud/RunHud.gd`, `ui/hud/RunHud.tscn` |
| `RunFeedbackLayer` | `ADIAR` | P3 | Funciona, mas não é prioridade estrutural | Pode ser redundante com outros feedbacks | Reavaliar depois da limpeza do core | `ui/feedback/RunFeedbackLayer.gd`, `ui/feedback/RunFeedbackLayer.tscn` |
| `WorldFeedbackLayer` | `MANTER COM AJUSTES` | P2 | Bom conceito para floating feedback | Busca player por grupo e usa reflexão leve | Manter; simplificar wiring | `ui/world_feedback/WorldFeedbackLayer.gd` |
| `FloatingCombatText` | `MANTER` | P2 | Boa peça visual independente | Nenhum grave | Preservar | `ui/world_feedback/FloatingCombatText.gd`, `ui/world_feedback/FloatingCombatText.tscn` |
| `DebugOverlay` | `MANTER COM AJUSTES` | P2 | Útil em debug | Muito polling e presença forte em runtime | Manter só em debug builds/flags | `ui/debug/DebugOverlay.gd`, `ui/debug/DebugOverlay.tscn` |
| `PrototypeToolsPanel` | `MANTER COM AJUSTES` | P2 | Ótimo para smoke tests | Não deveria moldar runtime final | Manter em tool/debug path | `ui/debug/tools/PrototypeToolsPanel.gd`, `ui/debug/tools/PrototypeToolsPanel.tscn` |

## 12. Spine e visual

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| Separação gameplay/visual | `MANTER` | P0 | Está correta e deve ser protegida | Regressão se colapsar para scripts monolíticos | Preservar como regra de arquitetura | `visual/*`, `gameplay/player/PlayerController.gd`, `gameplay/enemies/EnemyBase.gd` |
| `SpineVisualControllerBase` | `MANTER COM AJUSTES` | P2 | Abstração com valor real | Reflexão e busca dinâmica excessivas | Manter, tipar e simplificar resolução | `visual/spine/SpineVisualControllerBase.gd` |
| `SpineAnimationAdapterBase` | `MANTER COM AJUSTES` | P2 | Encapsula API Spine e tracks | Indireção/reflexão excessiva | Manter, simplificar e cachear melhor | `visual/spine/SpineAnimationAdapterBase.gd` |
| Controllers/adapters específicos Gaia/Goblin | `MANTER COM AJUSTES` | P2 | Especialização por personagem faz sentido | Alguns adapters são finos demais | Preservar controllers; avaliar absorver adapters triviais | `visual/characters/gaia/*`, `visual/enemies/goblin_warrior/*` |

## 13. Debug e ferramentas

| Sistema | Classificação | Prioridade | Motivo | Risco atual | Proposta | Arquivos |
|---|---|---:|---|---|---|---|
| `DeveloperAuditLogger` | `MANTER COM AJUSTES` | P2 | Bom ferramental | Pode contaminar runtime final | Manter com gating forte de canal/build | `autoloads/DeveloperAuditLogger.gd` |
| `RuntimeTreeSnapshot` | `MANTER` | P3 | Ferramenta útil para auditoria | Sem risco estrutural | Preservar | `core/debug/RuntimeTreeSnapshot.gd` |
| `DebugEnemyLinkDrawer` | `ADIAR` | P3 | Útil só em debugging específico | Baixo valor estrutural | Reavaliar depois | `ui/debug/DebugEnemyLinkDrawer.gd` |
| addon `godot_context_exporter` | `MANTER` | P3 | Ferramenta de contexto/editor | Não deve entrar no centro da arquitetura | Deixar isolado | `addons/godot_context_exporter/*` |

## 14. Resumo executivo de classificação

### MANTER

- `PoolManager`
- `DamageResolver`
- `DamagePayload`
- `RewardResolver`
- `LevelUpOptionService`
- `WeaponDefinition`, `EnemyDefinition`, `QueenDefinition`, `MapDefinition`
- separação gameplay/visual
- base Spine/visual conceitual

### MANTER COM AJUSTES

- `Main`
- `TestGaiaScene`
- `GameEvents`
- `SaveManager`
- `SaveData`
- `PlayerController`
- `EnemyBase`
- `EnemySpawner`
- `GaiaInitialWeaponController`
- `RunController`
- `RunHud`
- `LevelUpPanel`
- `WorldFeedbackLayer`
- `DeveloperAuditLogger`
- `SpineVisualControllerBase`
- `SpineAnimationAdapterBase`

### REFAZER USANDO GODOT NATIVO

- `InputManager`
- aplicação de upgrades
- `CoinDrop` / fluxo de magnetismo e coleta

### DESCARTAR

- arquivos `.tmp`
- duplicidade de attack area / source of truth paralela

### ADIAR

- `RunFeedbackLayer`
- `DebugEnemyLinkDrawer`
- refinamentos não centrais de tool/debug
