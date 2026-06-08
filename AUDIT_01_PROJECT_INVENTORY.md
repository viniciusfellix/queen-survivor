# AUDIT 01 - Project Inventory

## Escopo desta auditoria

Esta etapa foi feita em modo somente leitura sobre o código e os assets do projeto, sem alterações de gameplay, sem refatoração e sem remoção de arquivos.

Objetivos cobertos:

1. mapear a estrutura de pastas;
2. identificar cenas principais;
3. identificar autoloads;
4. identificar scripts centrais;
5. identificar resources `.tres`;
6. identificar sistemas de gameplay existentes;
7. identificar dependências entre sistemas;
8. identificar arquivos aparentemente ativos vs. residuais;
9. identificar possíveis erros de arquitetura Godot.

## Resumo executivo

O projeto está estruturado como um protótipo jogável Godot 4.x com boa separação entre:

- `autoloads/` para serviços globais;
- `definitions/` para tipos de `Resource`;
- `data/` para instâncias `.tres` editáveis;
- `runtime/` para estado temporário;
- `gameplay/` para lógica de run;
- `ui/` para HUD, painéis e debug;
- `visual/` para representação visual/Spine.

O fluxo principal atual é:

`project.godot` -> `scenes/Main.tscn` -> `scenes/Main.gd` -> `gameplay/test/TestGaiaScene.tscn`

Ou seja: o projeto sobe por uma cena raiz mínima e, a partir dela, carrega uma cena técnica de teste que hoje funciona como arena jogável principal do módulo.

## 1. Estrutura de pastas

### Top-level

- `.godot/`
- `_audit_export/`
- `addons/`
- `assets/`
- `autoloads/`
- `core/`
- `data/`
- `definitions/`
- `docs/`
- `gameplay/`
- `resources/`
- `runtime/`
- `save/`
- `scenes/`
- `tools/`
- `ui/`
- `visual/`

### Subpastas relevantes

#### `autoloads/`

- `App.gd`
- `DeveloperAuditLogger.gd`
- `GameEvents.gd`
- `InputManager.gd`
- `PoolManager.gd`
- `SaveManager.gd`

#### `core/`

- `constants/`
- `debug/`

#### `data/`

- `drops/`
- `enemies/`
- `localization/`
- `maps/`
- `queens/`
- `spawn_timelines/`
- `upgrade_pools/`
- `upgrades/`
- `weapons/`

#### `gameplay/`

- `arena/`
- `camera/`
- `combat/`
- `drops/`
- `enemies/`
- `level_up/`
- `player/`
- `run/`
- `spawners/`
- `test/`
- `weapons/`

#### `ui/`

- `debug/`
- `feedback/`
- `hud/`
- `level_up/`
- `result/`
- `world_feedback/`

#### `visual/`

- `characters/`
- `enemies/`
- `spine/`
- `weapons/`

### Contagem rápida de artefatos

- scripts `.gd`: 69
- cenas `.tscn`: 19
- resources `.tres`: 35

## 2. Cenas principais

### Cena de entrada do projeto

- `res://scenes/Main.tscn`
  - script: `res://scenes/Main.gd`
  - configurada em `project.godot` como `run/main_scene`
  - função: servir como root mínimo e carregar a cena inicial configurada por export em `Main.gd`

### Cena inicial realmente carregada no boot

- `res://gameplay/test/TestGaiaScene.tscn`
  - carregada por `scenes/Main.gd`
  - hoje é a cena jogável central do projeto
  - contém:
    - arena
    - runtime roots
    - player
    - spawner
    - run controller
    - drop controller
    - câmera
    - HUD
    - painéis de level up / resultado
    - overlays de debug

### Outras cenas importantes de runtime

- `res://gameplay/player/PlayerGaia.tscn`
- `res://gameplay/enemies/EnemyBase.tscn`
- `res://gameplay/spawners/EnemySpawner.tscn`
- `res://gameplay/drops/CoinDrop.tscn`
- `res://gameplay/weapons/attacks/DirectionalAttackHitbox.tscn`
- `res://gameplay/arena/TestArena.tscn`

### Cenas de UI ativas na run

- `res://ui/hud/RunHud.tscn`
- `res://ui/feedback/RunFeedbackLayer.tscn`
- `res://ui/world_feedback/WorldFeedbackLayer.tscn`
- `res://ui/level_up/LevelUpPanel.tscn`
- `res://ui/result/ResultPanel.tscn`
- `res://ui/debug/DebugOverlay.tscn`
- `res://ui/debug/tools/PrototypeToolsPanel.tscn`

### Cenas visuais

- `res://visual/characters/gaia/GaiaVisual.tscn`
- `res://visual/enemies/goblin_warrior/GoblinWarriorVisual.tscn`
- `res://visual/weapons/gaia_initial_weapon/GaiaAttackVisual.tscn`

## 3. Autoloads identificados

Conforme `project.godot [autoload]`:

- `DeveloperAuditLogger` -> `res://autoloads/DeveloperAuditLogger.gd`
- `GameEvents` -> `res://autoloads/GameEvents.gd`
- `PoolManager` -> `res://autoloads/PoolManager.gd`
- `SaveManager` -> `res://autoloads/SaveManager.gd`
- `InputManager` -> `res://autoloads/InputManager.gd`
- `App` -> `res://autoloads/App.gd`

### Papel de cada autoload

- `App`: boot técnico e locale atual via `TranslationServer.set_locale("pt_BR")`
- `GameEvents`: event bus global do projeto
- `InputManager`: leitura e normalização de input
- `PoolManager`: object pooling por cena/path
- `SaveManager`: save persistente em JSON e aplicação do resultado da run
- `DeveloperAuditLogger`: logger técnico por canais

## 4. Scripts centrais

### Boot e estrutura de cena

- `res://scenes/Main.gd`
- `res://gameplay/test/TestGaiaScene.gd`

### Coordenação de run

- `res://gameplay/run/RunController.gd`
- `res://gameplay/run/RunQuery.gd`
- `res://gameplay/run/RunResultPayload.gd`
- `res://gameplay/run/RewardResolver.gd`

### Runtime state

- `res://runtime/RunState.gd`
- `res://runtime/PlayerRuntimeState.gd`
- `res://runtime/SaveData.gd`

### Player / personagem

- `res://gameplay/player/PlayerController.gd`
- `res://gameplay/player/PlayerDashImpactArea.gd`

### Arma / ataque

- `res://gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `res://gameplay/weapons/attacks/DirectionalAttackHitbox.gd`

### Inimigos / spawn

- `res://gameplay/enemies/EnemyBase.gd`
- `res://gameplay/spawners/EnemySpawner.gd`

### Combate

- `res://gameplay/combat/HurtboxComponent.gd`
- `res://gameplay/combat/EnemyAttackHitbox.gd`
- `res://gameplay/combat/DamageResolver.gd`
- `res://gameplay/combat/DamagePayload.gd`

### Drops

- `res://gameplay/drops/DropController.gd`
- `res://gameplay/drops/CoinDrop.gd`

### Progressão / level up

- `res://gameplay/level_up/LevelUpOptionService.gd`

### UI

- `res://ui/hud/RunHud.gd`
- `res://ui/level_up/LevelUpPanel.gd`
- `res://ui/result/ResultPanel.gd`
- `res://ui/feedback/RunFeedbackLayer.gd`
- `res://ui/world_feedback/WorldFeedbackLayer.gd`
- `res://ui/world_feedback/FloatingCombatText.gd`

### Visual / Spine

- `res://visual/characters/gaia/GaiaVisualController.gd`
- `res://visual/characters/gaia/GaiaSpineAdapter.gd`
- `res://visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `res://visual/enemies/goblin_warrior/GoblinWarriorSpineAdapter.gd`
- `res://visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `res://visual/spine/SpineVisualControllerBase.gd`
- `res://visual/spine/SpineAnimationAdapterBase.gd`

### Infra / debug

- `res://ui/debug/DebugOverlay.gd`
- `res://ui/debug/DebugEnemyLinkDrawer.gd`
- `res://ui/debug/tools/PrototypeToolsPanel.gd`
- `res://core/debug/RuntimeTreeSnapshot.gd`

## 5. Resources `.tres` identificados

### Queens

- `res://data/queens/queen_gaia.tres`
- `res://data/queens/hurtbox_area_gaia_body.tres`
- `res://data/queens/gaia/dash_gaia_basic.tres`
- `res://data/queens/gaia/dash_impact_area_gaia_basic.tres`

### Enemies

- `res://data/enemies/enemy_chaser_basic.tres`
- `res://data/enemies/enemy_attack_chaser_basic_contact.tres`
- `res://data/enemies/attack_area_enemy_chaser_basic_contact.tres`
- `res://data/enemies/hurtbox_area_enemy_chaser_basic_body.tres`

### Weapons

- `res://data/weapons/weapon_gaia_initial.tres`
- `res://data/weapons/components/gaia_initial_physical.tres`
- `res://data/weapons/components/gaia_initial_magical.tres`
- `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

### Resources paralelos fora de `data/`

- `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`

### Map / run / spawn timeline

- `res://data/maps/map_test_arena_10min.tres`
- `res://data/spawn_timelines/test_arena_10min/spawn_timeline_test_arena_10min.tres`
- `res://data/spawn_timelines/test_arena_10min/wave_00_intro.tres`
- `res://data/spawn_timelines/test_arena_10min/wave_01_build_up.tres`
- `res://data/spawn_timelines/test_arena_10min/wave_02_pressure.tres`
- `res://data/spawn_timelines/test_arena_10min/wave_03_final_push.tres`

### Upgrades

- `res://data/upgrade_pools/upgrade_pool_gaia_default.tres`
- `res://data/upgrades/upgrade_weapon_physical_damage_flat.tres`
- `res://data/upgrades/upgrade_weapon_magical_damage_flat.tres`
- `res://data/upgrades/upgrade_weapon_hitbox_lifetime_percent.tres`
- `res://data/upgrades/upgrade_weapon_damage_flat.tres`
- `res://data/upgrades/upgrade_weapon_cooldown_percent.tres`
- `res://data/upgrades/upgrade_weapon_attack_area_scale_percent.tres`
- `res://data/upgrades/upgrade_player_move_speed_percent.tres`
- `res://data/upgrades/upgrade_player_max_hp_flat.tres`
- `res://data/upgrades/upgrade_player_heal_flat.tres`
- `res://data/upgrades/upgrade_player_defense_percent.tres`
- `res://data/upgrades/upgrade_coin_magnet_radius_percent.tres`
- `res://data/upgrades/upgrade_coin_collect_radius_percent.tres`

### Drops

- `res://data/drops/coin_default.tres`

### Spine data

- `res://assets/spine/gaia/gaia_spine_skeleton_data_resource.tres`
- `res://assets/spine/goblin-warrior/goblin_warrior_spine_skeleton_data_resource.tres`

## 6. Sistemas de gameplay existentes

### 6.1 Boot e montagem da cena

- `Main.gd` carrega a cena inicial.
- `TestGaiaScene.gd` monta a arena técnica e instancia o player.

### 6.2 Sistema de input

- centralizado em `InputManager`
- usa actions nativas em `project.godot`
- ações identificadas:
  - `move_left`
  - `move_right`
  - `move_up`
  - `move_down`
  - `dash`
  - `aim_left`
  - `aim_right`
  - `aim_up`
  - `aim_down`

### 6.3 Sistema de player

- `PlayerController.gd`
- inicializa a partir de `QueenDefinition`
- controla:
  - movimento
  - aim
  - dash
  - invulnerabilidade por hit
  - morte
  - hurtbox
  - upgrades de player
  - integração com arma

### 6.4 Sistema de arma da Gaia

- `GaiaInitialWeaponController.gd`
- usa `WeaponDefinition`
- instancia:
  - visual do ataque
  - hitbox do ataque
- atualiza cooldown
- aplica upgrades de dano/área/cooldown

### 6.5 Sistema de combate modular

- `HurtboxComponent.gd`
- `DirectionalAttackHitbox.gd`
- `EnemyAttackHitbox.gd`
- `DamageResolver.gd`
- `DamagePayload.gd`
- resources:
  - `AttackAreaDefinition`
  - `HurtboxAreaDefinition`
  - `DamageComponentDefinition`
  - `EnemyAttackDefinition`

Há uma separação razoável entre:

- shapes e dados de ataque em `Resource`;
- hitboxes/hurtboxes runtime em `Area2D`;
- cálculo de dano em `DamageResolver`.

### 6.6 Sistema de inimigos

- `EnemyBase.gd`
- `EnemySpawner.gd`
- `EnemyDefinition`
- `SpawnTimelineDefinition`
- `SpawnTimelineEntryDefinition`

Capacidades atuais:

- perseguição ao player
- dano por contato modular
- hurtbox para receber dano
- knockback
- body bump / slide
- morte com emissão de XP e chance de moeda
- pooling

### 6.7 Sistema de run

- `RunController.gd`
- `RunState.gd`
- `RunQuery.gd`
- `RunResultPayload.gd`
- `RewardResolver.gd`

Capacidades atuais:

- timer da run
- vitória por tempo
- derrota por morte do player
- XP e level
- moedas da run
- kills
- stats básicas
- construção do payload final
- emissão de eventos para UI e save

### 6.8 Sistema de level up / upgrades

- `LevelUpOptionService.gd`
- `LevelUpPanel.gd`
- `UpgradeDefinition`
- `UpgradePoolDefinition`

Capacidades atuais:

- seleção de opções válidas
- prevenção de repetição imediata
- limites por stack
- abertura/fechamento de painel
- aplicação da escolha via `GameEvents`

### 6.9 Sistema de drops e moedas

- `DropController.gd`
- `CoinDrop.gd`
- `CoinDropDefinition`

Capacidades atuais:

- escuta morte do inimigo
- chance de drop
- magnetismo
- coleta física
- atualização da economia da run

### 6.10 Sistema de save

- `SaveManager.gd`
- `SaveData.gd`

Capacidades atuais:

- criar save
- carregar save
- salvar em JSON no `user://`
- aplicar resultado da run ao save permanente

### 6.11 UI de gameplay

- `RunHud`
- `WorldFeedbackLayer`
- `FloatingCombatText`
- `RunFeedbackLayer`
- `ResultPanel`
- `LevelUpPanel`

### 6.12 Ferramentas técnicas / debug

- `DebugOverlay`
- `PrototypeToolsPanel`
- `RuntimeTreeSnapshot`
- `DeveloperAuditLogger`

## 7. Dependências entre sistemas

## Cadeia principal de runtime

- `project.godot`
  - aponta para `Main.tscn`
- `Main.gd`
  - carrega `TestGaiaScene.tscn`
- `TestGaiaScene.tscn`
  - instancia arena, player, spawner, run controller, drop controller e UI

## Dependências de boot

- `Main.gd` depende de:
  - `DeveloperAuditLogger`
  - cena inicial por path exportado

## Dependências da cena técnica

- `TestGaiaScene.gd` depende de:
  - `PlayerGaia.tscn`
  - `FollowCamera.gd`
  - `EnemySpawner`
  - `RunController`
  - `DropController`
  - roots nomeados da cena

## Dependências do player

- `PlayerController.gd` depende de:
  - `InputManager`
  - `GameEvents`
  - `DamageResolver`
  - `PlayerRuntimeState`
  - `QueenDefinition`
  - `HurtboxComponent`
  - `PlayerDashImpactArea`
  - controller visual
  - controller de arma presente na cena

## Dependências da arma

- `GaiaInitialWeaponController.gd` depende de:
  - `WeaponDefinition`
  - `PoolManager`
  - `GameEvents`
  - `DeveloperAuditLogger`
  - `DirectionalAttackHitbox.tscn`
  - `GaiaAttackVisual.tscn`

## Dependências dos inimigos

- `EnemySpawner.gd` depende de:
  - `RunQuery`
  - `PoolManager`
  - `SpawnTimelineDefinition`
  - `EnemyDefinition`
  - player runtime na árvore
  - root de inimigos

- `EnemyBase.gd` depende de:
  - `EnemyDefinition`
  - `HurtboxComponent`
  - `EnemyAttackHitbox`
  - `DamageResolver`
  - `GameEvents`
  - visual controller

## Dependências da run

- `RunController.gd` depende de:
  - `RunState`
  - `MapDefinition`
  - `UpgradePoolDefinition`
  - `LevelUpOptionService`
  - `RewardResolver`
  - `GameEvents`

## Dependências da UI

- `RunHud`, `LevelUpPanel`, `ResultPanel`, `WorldFeedbackLayer`, `RunFeedbackLayer`
  dependem majoritariamente de:
  - `GameEvents`
  - `RunQuery`
  - `SaveManager`
  - métodos `get_debug_data()` de player/run

## Padrão de integração predominante

O projeto usa três formas principais de dependência:

- referência por cena/NodePath;
- autoload global;
- evento global por `GameEvents`.

## 8. Arquivos aparentemente ativos

### Claramente ativos em runtime

- `project.godot`
- `scenes/Main.tscn`
- `scenes/Main.gd`
- todos os autoloads em `autoloads/`
- `gameplay/test/TestGaiaScene.tscn`
- `gameplay/test/TestGaiaScene.gd`
- `gameplay/player/PlayerGaia.tscn`
- `gameplay/player/PlayerController.gd`
- `gameplay/enemies/EnemyBase.tscn`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/spawners/EnemySpawner.tscn`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/run/*.gd`
- `gameplay/combat/*.gd`
- `gameplay/drops/*.gd`
- `ui/hud/RunHud.*`
- `ui/level_up/LevelUpPanel.*`
- `ui/result/ResultPanel.*`
- `ui/debug/DebugOverlay.*`
- `ui/debug/tools/PrototypeToolsPanel.*`
- `ui/world_feedback/*`
- `visual/characters/gaia/*`
- `visual/enemies/goblin_warrior/*`
- `visual/weapons/gaia_initial_weapon/*`
- resources `.tres` ligados ao mapa, queen, arma, inimigo, upgrades e drops

### Ativos para editor / tooling / documentação

- `addons/godot_context_exporter/*`
- `tools/audit/export_project_structure.gd`
- `tools/create_gaia_d_attack_area.gd`
- `docs/**`
- `_audit_export/godot_project_structure.txt`

### Provavelmente residuais, temporários ou de baixo valor runtime

- `gameplay/test/TestGaiaScene.tscn6158799705.tmp`
- `gameplay/test/TestGaiaScene.tscn6275747883.tmp`
- `gameplay/test/TestGaiaScene.tscn6283063278.tmp`
- `gameplay/player/PlayerGaia.tscn16296637380.tmp`
- `gameplay/player/PlayerGaia.tscn2451716848.tmp`

### Possíveis artefatos paralelos / fonte de confusão

- `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

Ambos descrevem área ofensiva de arma da Gaia, mas em lugares diferentes e com shapes/ids diferentes.

## 9. Sinais de arquivo residual ou divergência de fonte de verdade

### 9.1 Arquivos `.tmp` versionados no projeto

Há múltiplos `.tmp` de cenas em `gameplay/test/` e `gameplay/player/`.

Leitura desta auditoria:

- parecem artefatos temporários do editor;
- não parecem parte intencional da arquitetura;
- aumentam ruído de manutenção e risco de confusão.

### 9.2 Duas definições de attack area para a arma da Gaia

Foi encontrado:

- `PlayerGaia.tscn` referenciando `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `weapon_gaia_initial.tres` referenciando `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

Além disso, `GaiaInitialWeaponController.gd` aplica `weapon_definition` no `_ready()`, o que indica que a definição de arma tende a sobrescrever dados exportados da cena.

Leitura desta auditoria:

- existe chance alta de configuração duplicada;
- a cena do player pode conter um valor antigo ou residual;
- o `.tres` dentro de `resources/` parece menos alinhado com a convenção principal baseada em `data/`.

### 9.3 Nome de arquivo com extensão duplicada

Arquivo:

- `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

Leitura desta auditoria:

- não impede carregamento se a referência estiver correta;
- mas é um forte sinal de desorganização editorial e facilita erro humano em Inspector, scripts e documentação.

## 10. Possíveis erros ou riscos de arquitetura Godot

Esta seção não propõe solução ainda; apenas registra riscos observáveis.

### 10.1 Cena principal do jogo ainda aponta para uma cena técnica de teste

O `project.godot` sobe `Main.tscn`, e `Main.gd` carrega por padrão:

- `res://gameplay/test/TestGaiaScene.tscn`

Leitura:

- o fluxo jogável oficial ainda depende de uma cena de teste/protótipo;
- isso não é necessariamente errado para um módulo em desenvolvimento, mas é um forte indicador de arquitetura ainda provisória.

### 10.2 Mistura de source of truth entre cena e resource para arma

`PlayerGaia.tscn` exporta dados de ataque no `GaiaInitialWeaponController`, mas o próprio controller também aplica `WeaponDefinition` no `_ready()`.

Leitura:

- existe risco de valores configurados na cena não serem os realmente usados;
- para Godot, isso costuma virar dívida porque Inspector mostra uma coisa e runtime efetivo usa outra.

### 10.3 Dados semelhantes espalhados entre `data/` e `resources/`

A convenção dominante do projeto parece ser:

- tipos em `definitions/`
- instâncias editáveis em `data/`

Mas existe também:

- `resources/combat/attack_areas/attack_area_gaia_initial_d.tres`

Leitura:

- isso enfraquece a previsibilidade da organização;
- sugere legado parcial de uma organização anterior.

### 10.4 Locale forçada por código no autoload `App`

`App.gd` chama:

- `TranslationServer.set_locale("pt_BR")`

Leitura:

- a internacionalização existe e está registrada no `project.godot`;
- porém a locale final está hardcoded no boot;
- isso reduz aderência ao save/configuração de usuário e cria acoplamento de política de idioma no autoload.

### 10.5 Caminho fallback de ícone aparentemente inexistente

`ui/level_up/LevelUpPanel.gd` define:

- `DEFAULT_ICON_PATH = "res://assets/placeholders/upgrades/upgrade_default.png"`

Mas esse arquivo não foi encontrado no inventário.

Leitura:

- não quebra a cena atual porque `LevelUpPanel.tscn` já injeta `default_icon`;
- mesmo assim, o fallback por código aparenta estar inválido.

### 10.6 Forte dependência de grupos globais e buscas na árvore em utilitários/debug

Exemplos:

- `RunQuery` usa grupo `run_controller`
- vários sistemas procuram player por grupo `player`
- painéis e debug consultam `get_debug_data()` por busca de node

Leitura:

- isso é aceitável em protótipo e ferramentas;
- mas aumenta acoplamento implícito à estrutura da árvore e aos nomes de grupo.

### 10.7 Cena técnica concentra gameplay + UI + debug + ferramentas

`TestGaiaScene.tscn` agrega:

- arena
- runtime
- HUD
- feedback
- result panel
- level up panel
- debug overlay
- prototype tools

Leitura:

- a cena funciona como composition root do protótipo;
- porém mistura runtime jogável com tooling técnico na mesma montagem.

## 11. Leitura geral sobre estado do projeto

O projeto parece estar em um estágio intermediário bem organizado para prototipagem:

- já existe modelagem explícita com `Resource`;
- há separação entre runtime e persistência;
- a UI está desacoplada por eventos;
- o combate já tem uma arquitetura modular própria;
- pooling, save, localization e debug tooling já foram considerados.

Ao mesmo tempo, os sinais mais claros de maturidade incompleta são:

- cena principal ainda técnica;
- arquivos temporários presentes no repositório;
- duplicação de config de ataque/arma;
- nomenclatura e localização inconsistentes de alguns resources;
- presença simultânea de tooling e runtime na mesma cena base.

## 12. Conclusão desta etapa

O inventário foi concluído.

Neste momento, o projeto possui um núcleo de gameplay jogável centrado em:

- `TestGaiaScene`
- `PlayerController`
- `RunController`
- `EnemySpawner`
- `EnemyBase`
- `GaiaInitialWeaponController`
- `GameEvents`
- `SaveManager`

Os principais pontos de atenção para etapas futuras, sem ainda entrar em proposta de mudança, são:

- fonte de verdade de configuração da arma/attack area;
- arquivos temporários `.tmp`;
- assets/resources paralelos em `data/` e `resources/`;
- natureza ainda técnica da cena inicial do jogo.
