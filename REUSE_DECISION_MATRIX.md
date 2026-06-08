# REUSE DECISION MATRIX

## Legenda de classificação

1. `Reaproveitar sem alteração`
2. `Reaproveitar conceito, mas reimplementar`
3. `Reaproveitar parcialmente`
4. `Descartar implementação`
5. `Manter apenas como referência/documentação`

## Escalas usadas

### Custo

- `Baixo`
- `Médio`
- `Alto`

### Risco

- `Baixo`
- `Médio`
- `Alto`

### Compatibilidade com Godot

- `Alta`
- `Média`
- `Baixa`

---

## Matriz final

| Sistema atual | Classificação | Arquivos atuais | Motivo da classificação | Custo de manter | Custo de reimplementar | Risco de bug | Risco de overengineering | Compatibilidade com Godot | Recomendação final |
|---|---|---|---|---|---|---|---|---|---|
| Cena raiz `Main` | `3. Reaproveitar parcialmente` | `scenes/Main.tscn`, `scenes/Main.gd` | A ideia de root mínima é correta, mas hoje ela só encaminha para uma cena técnica de teste | Baixo | Baixo | Baixo | Baixo | Alta | Manter a cena raiz, mas redirecionar para uma cena oficial de gameplay |
| `TestGaiaScene` como composition root | `3. Reaproveitar parcialmente` | `gameplay/test/TestGaiaScene.tscn`, `gameplay/test/TestGaiaScene.gd` | Estruturalmente útil, semanticamente provisória e misturada com debug | Médio | Médio | Médio | Médio | Média | Reaproveitar a composição, mas promover/reorganizar como `RunScene` |
| Arquivos `.tmp` do editor | `4. Descartar implementação` | `gameplay/test/*.tmp`, `gameplay/player/*.tmp` | Não pertencem à arquitetura do produto | Alto se mantiver ruído contínuo | Baixo | Médio | Baixo | Baixa | Remover da base assim que entrar na fase de limpeza |
| `GameEvents` | `3. Reaproveitar parcialmente` | `autoloads/GameEvents.gd` | Event bus é útil, mas está largo demais e tende a virar solução universal | Médio | Médio | Médio | Alto | Média | Manter apenas para eventos realmente globais |
| `PoolManager` | `1. Reaproveitar sem alteração` | `autoloads/PoolManager.gd` | Infraestrutura válida e muito adequada para survivor-like | Baixo | Médio | Baixo | Baixo | Alta | Preservar como parte do core técnico |
| `SaveManager` | `3. Reaproveitar parcialmente` | `autoloads/SaveManager.gd` | Bom ponto central de persistência, mas backend manual é desnecessário | Médio | Médio | Médio | Médio | Alta | Manter o papel arquitetural e simplificar persistência |
| `DeveloperAuditLogger` | `3. Reaproveitar parcialmente` | `autoloads/DeveloperAuditLogger.gd`, `core/constants/DeveloperLogChannels.gd` | Útil para dev e QA, mas não deve contaminar builds finais | Médio | Médio | Baixo | Médio | Alta | Manter como ferramental de debug com gating forte |
| `App` | `3. Reaproveitar parcialmente` | `autoloads/App.gd` | Bootstrap é aceitável, mas muito pequeno para justificar tanto acoplamento | Baixo | Baixo | Baixo | Baixo | Alta | Enxugar para bootstrap mínimo ou absorver parte em config |
| `InputManager` | `2. Reaproveitar conceito, mas reimplementar` | `autoloads/InputManager.gd` | A intenção de normalizar input é boa, mas o autoload global é pouco idiomático para 1 player local | Médio | Baixo | Médio | Alto | Baixa | Reimplementar input diretamente no player usando Input Map nativo |
| `WeaponDefinition` | `1. Reaproveitar sem alteração` | `definitions/WeaponDefinition.gd`, `data/weapons/weapon_gaia_initial.tres` | Modelo data-driven é correto e valioso | Baixo | Alto | Baixo | Baixo | Alta | Preservar como fonte oficial da arma |
| `QueenDefinition` | `1. Reaproveitar sem alteração` | `definitions/QueenDefinition.gd`, `data/queens/queen_gaia.tres` | Resource de configuração da personagem faz total sentido | Baixo | Alto | Baixo | Baixo | Alta | Manter |
| `EnemyDefinition` | `1. Reaproveitar sem alteração` | `definitions/EnemyDefinition.gd`, `data/enemies/enemy_chaser_basic.tres` | Boa fundação data-driven para inimigos | Baixo | Alto | Baixo | Baixo | Alta | Manter e apenas fortalecer validação no futuro |
| `MapDefinition` | `1. Reaproveitar sem alteração` | `definitions/MapDefinition.gd`, `data/maps/map_test_arena_10min.tres` | Simples, clara e alinhada ao domínio | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `UpgradeDefinition` | `1. Reaproveitar sem alteração` | `definitions/UpgradeDefinition.gd`, `data/upgrades/*.tres` | A definição de conteúdo está boa; o problema é na aplicação | Baixo | Alto | Baixo | Médio | Alta | Manter |
| `UpgradePoolDefinition` | `1. Reaproveitar sem alteração` | `definitions/UpgradePoolDefinition.gd`, `data/upgrade_pools/*.tres` | Boa estrutura para seleção de upgrades | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `AttackAreaDefinition` / `HurtboxAreaDefinition` | `3. Reaproveitar parcialmente` | `definitions/AttackAreaDefinition.gd`, `definitions/HurtboxAreaDefinition.gd`, `definitions/CombatShapeDefinition.gd` | O contrato é bom, mas a aplicação dinâmica em tudo adiciona peso desnecessário | Médio | Médio | Médio | Médio | Alta | Manter o contrato, simplificar o uso por cena quando possível |
| `DamageComponentDefinition` | `1. Reaproveitar sem alteração` | `definitions/DamageComponentDefinition.gd`, `data/weapons/components/*.tres` | Útil para dano composto e expansão futura | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| Attack areas duplicadas da Gaia | `4. Descartar implementação` | `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`, `data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`, referências em `PlayerGaia.tscn` e `weapon_gaia_initial.tres` | Dupla source of truth gera inconsistência e confusão editorial | Alto | Baixo | Alto | Alto | Média | Escolher 1 fonte oficial e descartar a outra implementação |
| Contrato `BodyCollision` vs `Hitbox` vs `Hurtbox` | `1. Reaproveitar sem alteração` | `gameplay/combat/*`, cenas `PlayerGaia.tscn`, `EnemyBase.tscn`, docs de layers | É um dos melhores pontos da base atual | Baixo | Alto | Baixo | Baixo | Alta | Proteger esse contrato explicitamente |
| `DamagePayload` | `1. Reaproveitar sem alteração` | `gameplay/combat/DamagePayload.gd` | DTO de dano claro e útil | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `DamageResolver` | `1. Reaproveitar sem alteração` | `gameplay/combat/DamageResolver.gd` | Regra matemática central bem separada | Baixo | Alto | Baixo | Baixo | Alta | Manter |
| `HurtboxComponent` | `3. Reaproveitar parcialmente` | `gameplay/combat/HurtboxComponent.gd` | O componente é útil, mas pode ser simplificado em cenários fixos | Médio | Médio | Médio | Médio | Alta | Reaproveitar o conceito e simplificar onde a cena já resolve |
| `DirectionalAttackHitbox` | `3. Reaproveitar parcialmente` | `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`, `.tscn` | Bom ataque ativo, mas com lógica duplicada em relação a outras áreas ofensivas | Médio | Médio | Médio | Médio | Alta | Usar como base de referência para uma hitbox ofensiva consolidada |
| `EnemyAttackHitbox` | `3. Reaproveitar parcialmente` | `gameplay/combat/EnemyAttackHitbox.gd` | Estruturalmente correto, mas redundante com outros pipelines ofensivos | Médio | Médio | Médio | Médio | Alta | Consolidar infraestrutura, manter papel |
| `PlayerDashImpactArea` | `3. Reaproveitar parcialmente` | `gameplay/player/PlayerDashImpactArea.gd` | Dash ofensivo separado é correto; implementação ainda duplicada | Médio | Médio | Médio | Médio | Alta | Reaproveitar como subsistema, convergindo com hitbox comum |
| `PlayerController` | `3. Reaproveitar parcialmente` | `gameplay/player/PlayerController.gd` | Muita regra útil já existe, mas o script está monolítico | Alto | Alto | Alto | Alto | Média | Fatiar progressivamente sem reboot total |
| `PlayerRuntimeState` | `3. Reaproveitar parcialmente` | `runtime/PlayerRuntimeState.gd` | A ideia de estado runtime é boa; o escopo atual está largo demais | Médio | Médio | Médio | Médio | Média | Enxugar para stats e flags realmente úteis |
| `PlayerGaia.tscn` | `3. Reaproveitar parcialmente` | `gameplay/player/PlayerGaia.tscn` | Boa base de cena do player, mas contém config redundante da arma | Médio | Médio | Médio | Médio | Alta | Manter a cena, limpar exports duplicados |
| `GaiaInitialWeaponController` | `3. Reaproveitar parcialmente` | `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` | O comportamento da arma já está codificado, mas com escopo muito grande | Alto | Alto | Alto | Alto | Média | Reaproveitar a intenção e a maior parte das regras, mas reestruturar |
| `GaiaAttackVisualController` | `3. Reaproveitar parcialmente` | `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`, `.tscn` | Visual simples e funcional, mas com caminhos e modos além do necessário agora | Médio | Baixo | Baixo | Médio | Alta | Manter como visual simples, simplificando resolução |
| `EnemyBase` | `3. Reaproveitar parcialmente` | `gameplay/enemies/EnemyBase.gd`, `.tscn` | Muito valor já existe, mas o acúmulo de responsabilidades é alto | Alto | Alto | Alto | Alto | Média | Fatiar em movimento/combat/reward mantendo comportamento |
| `EnemySpawner` | `3. Reaproveitar parcialmente` | `gameplay/spawners/EnemySpawner.gd`, `.tscn` | Timeline + pooling são bons, mas o wiring está implícito demais | Médio | Médio | Médio | Médio | Alta | Manter o sistema, explicitar dependências |
| Goblin atual | `1. Reaproveitar sem alteração` | `data/enemies/enemy_chaser_basic.tres`, `visual/enemies/goblin_warrior/*` | Excelente baseline de regressão e conteúdo mínimo | Baixo | Médio | Baixo | Baixo | Alta | Manter como inimigo benchmark |
| Body bump / player body slide / knockback | `3. Reaproveitar parcialmente` | principal em `gameplay/enemies/EnemyBase.gd`, `gameplay/player/PlayerController.gd`, `PlayerDashImpactArea.gd` | Mecânicas fazem sentido para hordas, mas implementação está concentrada demais | Alto | Médio | Alto | Alto | Média | Preservar mecânica, simplificar a implementação |
| `DropController` | `3. Reaproveitar parcialmente` | `gameplay/drops/DropController.gd` | Responsabilidade está correta; wiring pode ser mais explícito | Médio | Baixo | Médio | Baixo | Alta | Manter controlador, simplificando acoplamentos |
| `CoinDrop` | `2. Reaproveitar conceito, mas reimplementar` | `gameplay/drops/CoinDrop.gd`, `.tscn` | A ideia de moeda física com magnetismo é boa, mas o desenho pode ficar bem mais idiomático com `Area2D` dedicadas | Médio | Médio | Médio | Médio | Média | Reimplementar em torno de `MagnetArea` + `CollectArea` |
| `CoinDropDefinition` | `1. Reaproveitar sem alteração` | `definitions/CoinDropDefinition.gd`, `data/drops/coin_default.tres` | Configuração de moeda é útil e correta | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| XP direta na run | `1. Reaproveitar sem alteração` | fluxo principal em `gameplay/run/RunController.gd`, `enemy_died` event | Simples e apropriado para a fase atual | Baixo | Médio | Baixo | Baixo | Alta | Manter XP direta por enquanto |
| `LevelUpOptionService` | `1. Reaproveitar sem alteração` | `gameplay/level_up/LevelUpOptionService.gd` | Serviço puro, bem separado e com bom custo/benefício | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| Aplicação de upgrades | `2. Reaproveitar conceito, mas reimplementar` | espalhada em `gameplay/run/RunController.gd`, `gameplay/player/PlayerController.gd`, `gameplay/weapons/gaia/GaiaInitialWeaponController.gd` | O conceito está certo; a distribuição da lógica é o problema | Alto | Médio | Alto | Alto | Média | Criar um applier central de upgrades |
| `LevelUpPanel` | `3. Reaproveitar parcialmente` | `ui/level_up/LevelUpPanel.gd`, `.tscn` | UI está conceitualmente boa, mas é muito hardcoded | Médio | Baixo | Baixo | Médio | Alta | Manter o painel, simplificando implementação |
| `RunController` | `3. Reaproveitar parcialmente` | `gameplay/run/RunController.gd` | Core da run já existe, mas centraliza coisas demais | Alto | Alto | Alto | Alto | Média | Fatiar progressivamente e preservar comportamento |
| `RunState` | `3. Reaproveitar parcialmente` | `runtime/RunState.gd` | Separa run de save, o que é correto; pode ser mais enxuto | Médio | Médio | Médio | Médio | Média | Manter o conceito, reduzir escopo |
| `RunResultPayload` | `1. Reaproveitar sem alteração` | `gameplay/run/RunResultPayload.gd` | DTO simples e correto | Baixo | Baixo | Baixo | Baixo | Alta | Manter |
| `RewardResolver` | `1. Reaproveitar sem alteração` | `gameplay/run/RewardResolver.gd` | Serviço puro, simples, correto | Baixo | Baixo | Baixo | Baixo | Alta | Manter |
| `SaveData` schema | `3. Reaproveitar parcialmente` | `runtime/SaveData.gd` | O schema geral é bom, mas a serialização manual não precisa ser definitiva | Médio | Médio | Médio | Médio | Alta | Preservar o conteúdo, migrar backend quando oportuno |
| Persistência JSON manual | `2. Reaproveitar conceito, mas reimplementar` | `autoloads/SaveManager.gd`, `runtime/SaveData.gd` | Persistência única faz sentido; o formato manual sobre `Resource` é que é excessivo | Médio | Baixo | Médio | Médio | Média | Migrar para serialização nativa de `Resource` quando estabilizar |
| `ResultPanel` | `1. Reaproveitar sem alteração` | `ui/result/ResultPanel.gd`, `.tscn` | Painel passivo, com responsabilidade correta | Baixo | Baixo | Baixo | Baixo | Alta | Manter |
| `RunHud` | `3. Reaproveitar parcialmente` | `ui/hud/RunHud.gd`, `.tscn` | HUD necessária, mas atualizada por polling e API de debug | Médio | Médio | Médio | Médio | Média | Manter a UI, reimplementar o fluxo de atualização por signals |
| `RunFeedbackLayer` | `3. Reaproveitar parcialmente` | `ui/feedback/RunFeedbackLayer.gd`, `.tscn` | Funciona, mas seu valor final ainda não está totalmente claro | Médio | Baixo | Baixo | Médio | Alta | Manter como opcional até nova avaliação de UX |
| `WorldFeedbackLayer` | `3. Reaproveitar parcialmente` | `ui/world_feedback/WorldFeedbackLayer.gd`, `.tscn` | Boa ideia e boa separação, com wiring ainda simplificável | Médio | Baixo | Baixo | Baixo | Alta | Manter conceito e simplificar referências |
| `FloatingCombatText` | `1. Reaproveitar sem alteração` | `ui/world_feedback/FloatingCombatText.gd`, `.tscn` | Componente visual limpo e útil | Baixo | Baixo | Baixo | Baixo | Alta | Manter |
| `DebugOverlay` | `3. Reaproveitar parcialmente` | `ui/debug/DebugOverlay.gd`, `.tscn` | Ferramenta útil, mas não deve viver no runtime final do jogo | Médio | Médio | Baixo | Médio | Alta | Manter em `DebugRoot` / builds de debug |
| `PrototypeToolsPanel` | `3. Reaproveitar parcialmente` | `ui/debug/tools/PrototypeToolsPanel.gd`, `.tscn` | Excelente para smoke tests, inadequado como parte permanente da cena principal | Médio | Médio | Baixo | Médio | Alta | Manter como ferramenta de debug, não como parte do jogo final |
| `RuntimeTreeSnapshot` | `5. Manter apenas como referência/documentação` | `core/debug/RuntimeTreeSnapshot.gd`, docs associadas | Ferramenta de auditoria e diagnóstico, não de gameplay | Baixo | Médio | Baixo | Baixo | Alta | Manter como tool/debug/documentação |
| `DebugEnemyLinkDrawer` | `5. Manter apenas como referência/documentação` | `ui/debug/DebugEnemyLinkDrawer.gd` | Utilidade restrita a inspeção visual pontual | Médio | Baixo | Baixo | Baixo | Alta | Manter apenas em debug, sem prioridade arquitetural |
| `SpineVisualControllerBase` | `1. Reaproveitar sem alteração` | `visual/spine/SpineVisualControllerBase.gd` | Abstração com valor real para separar gameplay e visual | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `SpineAnimationAdapterBase` | `3. Reaproveitar parcialmente` | `visual/spine/SpineAnimationAdapterBase.gd` | Encapsula a API Spine, mas com reflexão e indireção além do necessário | Médio | Médio | Baixo | Médio | Média | Manter a ideia e simplificar implementação |
| `GaiaVisualController` | `1. Reaproveitar sem alteração` | `visual/characters/gaia/GaiaVisualController.gd`, `.tscn` | Boa separação entre estado e apresentação | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `GoblinWarriorVisualController` | `1. Reaproveitar sem alteração` | `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`, `.tscn` | Mesmo motivo da Gaia: visual especializado e desacoplado | Baixo | Médio | Baixo | Baixo | Alta | Manter |
| `GaiaSpineAdapter` / `GoblinWarriorSpineAdapter` | `3. Reaproveitar parcialmente` | `visual/characters/gaia/GaiaSpineAdapter.gd`, `visual/enemies/goblin_warrior/GoblinWarriorSpineAdapter.gd` | Pontos explícitos por personagem são úteis, mas as subclasses atuais são finas demais | Médio | Baixo | Baixo | Médio | Média | Avaliar absorver parte da lógica na base sem perder clareza |
| addon `godot_context_exporter` | `5. Manter apenas como referência/documentação` | `addons/godot_context_exporter/*` | Ferramenta de apoio/editor, não parte do produto | Baixo | Médio | Baixo | Baixo | Alta | Manter isolado, sem mexer no core |
| Documentação arquitetural atual | `5. Manter apenas como referência/documentação` | `docs/**`, `AUDIT_*.md`, `TARGET_ARCHITECTURE_GODOT_NATIVE.md` | Material valioso para migração e onboarding | Baixo | Alto | Baixo | Baixo | Alta | Preservar e atualizar ao longo da migração |

---

## Resumo executivo por classe

## 1. Reaproveitar sem alteração

Sistemas que já estão bons o suficiente e merecem ser protegidos:

- `PoolManager`
- `WeaponDefinition`
- `QueenDefinition`
- `EnemyDefinition`
- `MapDefinition`
- `UpgradeDefinition`
- `UpgradePoolDefinition`
- contrato `BodyCollision` vs `Hitbox` vs `Hurtbox`
- `DamagePayload`
- `DamageResolver`
- Goblin atual como conteúdo
- XP direta
- `LevelUpOptionService`
- `RunResultPayload`
- `RewardResolver`
- `ResultPanel`
- `FloatingCombatText`
- `SpineVisualControllerBase`
- `GaiaVisualController`
- `GoblinWarriorVisualController`

## 2. Reaproveitar conceito, mas reimplementar

Sistemas cujo objetivo está certo, mas cuja implementação atual não deve ser levada adiante:

- `InputManager`
- `CoinDrop`
- aplicação de upgrades
- persistência JSON manual

## 3. Reaproveitar parcialmente

Sistemas com muito valor reaproveitável, mas que precisam de poda ou decomposição:

- `Main`
- `TestGaiaScene`
- `GameEvents`
- `SaveManager`
- `DeveloperAuditLogger`
- `App`
- `AttackAreaDefinition` / `HurtboxAreaDefinition`
- `HurtboxComponent`
- `DirectionalAttackHitbox`
- `EnemyAttackHitbox`
- `PlayerDashImpactArea`
- `PlayerController`
- `PlayerRuntimeState`
- `PlayerGaia.tscn`
- `GaiaInitialWeaponController`
- `GaiaAttackVisualController`
- `EnemyBase`
- `EnemySpawner`
- body bump / slide / knockback
- `DropController`
- `LevelUpPanel`
- `RunController`
- `RunState`
- `SaveData` schema
- `RunHud`
- `RunFeedbackLayer`
- `WorldFeedbackLayer`
- `DebugOverlay`
- `PrototypeToolsPanel`
- `SpineAnimationAdapterBase`
- `GaiaSpineAdapter` / `GoblinWarriorSpineAdapter`

## 4. Descartar implementação

Sistemas/artefatos que não merecem ser mantidos como implementação:

- arquivos `.tmp`
- duplicidade de attack area / source of truth paralela da Gaia

## 5. Manter apenas como referência/documentação

Itens úteis como histórico, tool ou documentação, mas não como parte do core de runtime:

- `RuntimeTreeSnapshot`
- `DebugEnemyLinkDrawer`
- addon `godot_context_exporter`
- documentação `docs/**`
- relatórios `AUDIT_*.md`
- `TARGET_ARCHITECTURE_GODOT_NATIVE.md`

---

## Recomendação final do projeto

### Estratégia recomendada

Não fazer reboot total.

Fazer:

1. limpeza de resíduos e source of truth;
2. substituição dos pontos pouco idiomáticos por fluxos Godot nativos;
3. decomposição dos monólitos centrais;
4. preservação dos bons contratos já existentes.

### Núcleo a proteger

- modelo data-driven;
- contrato de combate;
- pooling;
- separação gameplay/visual;
- run separada de save;
- visual Spine.

### Núcleo a reconstruir com cuidado

- input;
- moedas/magnetismo;
- aplicação de upgrades;
- HUD por signals;
- decomposição de player, inimigo, arma e run controller.

### Conclusão

O projeto atual tem **mais coisa reaproveitável do que descartável**, mas a maior parte do valor está:

- no desenho conceitual;
- nos contratos de domínio;
- e nas resources.

Já a maior parte da dívida está:

- nos scripts centrais grandes;
- na duplicação de source of truth;
- e em algumas camadas próprias onde a Godot nativa resolveria melhor.
