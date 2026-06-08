# TARGET ARCHITECTURE - GODOT NATIVE

## Objetivo

Definir uma arquitetura-alvo mínima, profissional e idiomática para Godot 4.x para o projeto Queen Survivors.

Princípios:

- usar nodes nativos da Godot antes de abstrações próprias;
- manter data-driven onde isso realmente ajuda;
- separar gameplay de visual;
- separar física de dano;
- usar `signals` para comunicação entre sistemas desacoplados;
- evitar autoloads desnecessários;
- evitar scripts monolíticos;
- preservar o que já está bom na base atual.

## Princípios globais

## 1. Regras de composição

- cena monta comportamento;
- script executa regra;
- `Resource` descreve configuração;
- UI exibe estado, não calcula gameplay;
- visual representa estado, não decide gameplay.

## 2. Regras de runtime

- `CharacterBody2D` para entidades que se movem e colidem fisicamente;
- `Area2D` para dano, coleta, magnetismo, triggers e zonas;
- `CollisionShape2D` para shapes estáticas ou simples;
- `Resource` para conteúdo editável por designers;
- `Timer` ou `SceneTreeTimer` só quando necessário;
- `PoolManager` mantido para entidades de alta rotatividade.

## 3. Regras de comunicação

Preferência:

1. referência direta por composição de cena;
2. `signal` local;
3. autoload/event bus só para eventos realmente globais.

## 4. Autoloads alvo

Manter somente:

- `GameEvents`
- `PoolManager`
- `SaveManager`

Opcional em debug:

- `DeveloperAuditLogger`

Não usar autoload para input do player.

## 5. Layers e masks alvo

Manter a convenção atual:

| Layer | Nome | Uso |
|---:|---|---|
| 1 | `World` | ambiente/obstáculo |
| 2 | `PlayerBody` | corpo físico da Gaia |
| 3 | `EnemyBody` | corpo físico de inimigos |
| 4 | `PlayerAttackHitbox` | ataques da Gaia |
| 5 | `EnemyHurtbox` | áreas vulneráveis dos inimigos |
| 6 | `EnemyAttackHitbox` | ataques inimigos |
| 7 | `PlayerHurtbox` | área vulnerável da Gaia |
| 8 | `DropPickup` | coleta/drops |

Regra:

- `BodyCollision` nunca decide dano;
- dano sempre por `Area2D` ofensiva contra `Area2D` vulnerável.

---

## Sistema 1 - Cena principal de gameplay

## Arquitetura alvo

### Nodes recomendados

`RunScene.tscn`

- `RunScene` (`Node2D`)
  - `ArenaRoot` (`Node2D`)
  - `RuntimeRoot` (`Node2D`)
    - `PlayerRoot` (`Node2D`)
    - `EnemyRoot` (`Node2D`)
    - `DropRoot` (`Node2D`)
    - `SpawnerRoot` (`Node2D`)
    - `RunController` (`Node`)
    - `DropController` (`Node`)
    - `XpCollectorController` (`Node`) opcional se XP direta for por item
  - `Camera2D`
  - `UiRoot` (`CanvasLayer` ou agrupamento por cenas UI)
    - `RunHud`
    - `LevelUpPanel`
    - `ResultPanel`
    - `WorldFeedbackLayer`
  - `DebugRoot` (apenas debug)

### Scripts recomendados

- `RunScene.gd`
- `RunController.gd`
- `DropController.gd`
- `FollowCamera.gd`

### Resources recomendados

- `MapDefinition`
- `SpawnTimelineDefinition`
- `UpgradePoolDefinition`

### Signals usados

Locais:

- `player_spawned(player)`
- `run_scene_ready()`

Globais via `GameEvents`:

- `run_started`
- `run_finished`

### Layers/masks

- sem layers próprias; é cena de composição

### O que reaproveitar da base atual

- `scenes/Main.tscn`
- `scenes/Main.gd`
- estrutura geral de `TestGaiaScene.tscn`
- `FollowCamera.gd`

### O que descartar

- dependência semântica de `gameplay/test/TestGaiaScene.tscn` como cena oficial
- mistura obrigatória de debug tools no root da run

### Ordem de implementação

1. promover/duplicar a cena técnica para uma `RunScene` oficial
2. separar `DebugRoot`
3. manter o wiring atual

---

## Sistema 2 - Player / Gaia

## Arquitetura alvo

### Nodes recomendados

`PlayerGaia.tscn`

- `PlayerGaia` (`CharacterBody2D`)
  - `BodyCollision` (`CollisionShape2D`)
  - `PlayerHurtbox` (`Area2D`)
    - `CollisionShape2D` ou múltiplas shapes
  - `DashImpactArea` (`Area2D`)
    - `CollisionShape2D` runtime ou fixa
  - `VisualRoot` (`Node2D`)
    - `GaiaVisual`
  - `WeaponRoot` (`Node2D`)
    - `AttackOrigin` (`Marker2D`)
    - `AttackVisualRoot` (`Node2D`)
    - `AttackHitboxRoot` (`Node2D`)
    - `PrimaryWeaponController`
  - `CollectArea` (`Area2D`) opcional para moeda/xp física
    - `CollisionShape2D`
  - `MagnetArea` (`Area2D`) opcional
    - `CollisionShape2D`

### Scripts recomendados

- `PlayerController.gd`
- `PlayerStatsRuntime.gd` ou `PlayerRuntimeState.gd` enxuto
- `PlayerDashComponent.gd`
- `PlayerHurtbox.gd` só se `HurtboxComponent` não for suficiente

### Resources recomendados

- `QueenDefinition`
- `QueenDashDefinition`
- `HurtboxAreaDefinition`

### Signals usados

Locais:

- `dashed_started(direction)`
- `dash_finished()`
- `hp_changed(current_hp, max_hp)`
- `died(source_id)`
- `damage_received(payload, final_damage)`

Globais:

- `player_damaged`
- `player_died`

### Layers/masks

- `PlayerGaia` body:
  - layer 2 `PlayerBody`
  - mask 1 `World`
  - opcionalmente sem colisão com `EnemyBody`
- `PlayerHurtbox`:
  - layer 7 `PlayerHurtbox`
  - mask 0
- `DashImpactArea`:
  - layer 4 `PlayerAttackHitbox`
  - mask 5 `EnemyHurtbox`
- `CollectArea` / `MagnetArea`:
  - layer opcional 8 `DropPickup` ou neutra
  - mask conforme o tipo de item detectado

### O que reaproveitar da base atual

- `gameplay/player/PlayerGaia.tscn`
- `gameplay/player/PlayerController.gd`
- `data/queens/queen_gaia.tres`
- `definitions/QueenDefinition.gd`
- `definitions/QueenDashDefinition.gd`
- `gameplay/player/PlayerDashImpactArea.gd`

### O que descartar

- input global via `InputManager`
- estado runtime carregando informação demais de input/visual
- wiring implícito por grupo para tudo

### Ordem de implementação

1. simplificar input dentro de `PlayerController`
2. extrair dash para componente local
3. reduzir `PlayerRuntimeState` ao essencial
4. manter contrato de dano

---

## Sistema 3 - Movimento

## Arquitetura alvo

### Nodes recomendados

- embutido em `PlayerGaia` via `CharacterBody2D`
- embutido em `EnemyBase` via `CharacterBody2D`

### Scripts recomendados

- `PlayerController.gd`
- `EnemyMovementComponent.gd`

### Resources recomendados

- stats vindas de `QueenDefinition`
- stats vindas de `EnemyDefinition`

### Signals usados

Locais:

- `movement_state_changed(is_moving, direction)`

### Layers/masks

- `PlayerBody` e `EnemyBody`

### O que reaproveitar da base atual

- `CharacterBody2D` no player e inimigos
- parâmetros de move speed atuais
- lógica de slide/knockback como intenção

### O que descartar

- duplicação de busca de target por grupo em múltiplos lugares
- misturar movimento, dano, loot e visual no mesmo método gigante

### Ordem de implementação

1. estabilizar movimento do player
2. estabilizar chase do inimigo
3. isolar knockback e body slide

---

## Sistema 4 - Mira

## Arquitetura alvo

### Nodes recomendados

- nenhum node extra obrigatório
- opcional `AimPivot` (`Node2D`) se a arma ou visual precisarem pivot explícito

### Scripts recomendados

- mira lida no `PlayerController.gd`

### Resources recomendados

- nenhum obrigatório

### Signals usados

Locais:

- `aim_direction_changed(direction)`

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- cálculo atual de aim por mouse/analógico
- distinção entre aim direction e facing direction

### O que descartar

- necessidade de autoload para armazenar aim global

### Ordem de implementação

1. mover leitura de aim para o player
2. manter `last_valid_aim_direction`
3. expor ao visual e à arma via método ou propriedade local

---

## Sistema 5 - Dash

## Arquitetura alvo

### Nodes recomendados

- `DashImpactArea` (`Area2D`) no player
- sem nodes extras além disso

### Scripts recomendados

- `PlayerDashComponent.gd`
- `PlayerDashImpactArea.gd`

### Resources recomendados

- `QueenDashDefinition`
- `AttackAreaDefinition` para área ofensiva do dash

### Signals usados

Locais:

- `dash_started(direction)`
- `dash_finished()`
- `dash_cooldown_started(seconds)`

Globais:

- opcional nenhum; dash não precisa de evento global obrigatório

### Layers/masks

- impacto ofensivo do dash:
  - layer 4 `PlayerAttackHitbox`
  - mask 5 `EnemyHurtbox`

### O que reaproveitar da base atual

- `PlayerDashImpactArea.gd`
- `QueenDashDefinition`
- política de invulnerabilidade e interação com arma, mas simplificada

### O que descartar

- acoplamento excessivo entre dash, visual, cooldown de arma e múltiplas políticas no mesmo bloco

### Ordem de implementação

1. separar o controlador de dash do resto do player
2. manter a impact area como subsistema ofensivo
3. reintroduzir regras especiais aos poucos

---

## Sistema 6 - HP / dano

## Arquitetura alvo

### Nodes recomendados

Por entidade combatente:

- `BodyCollision` (`CollisionShape2D`) para física
- `Hurtbox` (`Area2D`) para vulnerabilidade
  - `CollisionShape2D`

Opcional futuro:

- `HealthComponent` como script em `Node` filho, se necessário

### Scripts recomendados

- `HurtboxComponent.gd`
- `DamagePayload.gd`
- `DamageResolver.gd`
- `HealthComponent.gd` opcional futuro

### Resources recomendados

- `HurtboxAreaDefinition`
- `DamageComponentDefinition`
- `EnemyAttackDefinition`
- `WeaponDefinition`

### Signals usados

Locais:

- `damage_received(payload, final_damage)`
- `hp_changed(current_hp, max_hp)`
- `died(source_id)`

Globais:

- `player_damaged`
- `player_died`
- `enemy_damaged`
- `enemy_died`

### Layers/masks

- `PlayerHurtbox`:
  - layer 7
- `EnemyHurtbox`:
  - layer 5
- ofensivas:
  - player attack layer 4 / mask 5
  - enemy attack layer 6 / mask 7

### O que reaproveitar da base atual

- `DamagePayload.gd`
- `DamageResolver.gd`
- `HurtboxComponent.gd`
- separação body/hurtbox/hitbox

### O que descartar

- reflexão desnecessária no caminho quente quando o tipo do receiver já é conhecido

### Ordem de implementação

1. congelar o contrato atual
2. reduzir indireção/reflexão
3. simplificar shape runtime onde a cena fixa resolver melhor

---

## Sistema 7 - Ataque

## Arquitetura alvo

### Nodes recomendados

Na arma melee atual:

- `PrimaryWeaponController` (`Node`)
- `AttackOrigin` (`Marker2D`)
- hitbox ofensiva instanciada em `AttackHitboxRoot`
- visual instanciado em `AttackVisualRoot`

Hitbox de ataque:

- `AttackHitbox.tscn`
  - `Area2D`
    - `CollisionShape2D` ou múltiplas shapes

### Scripts recomendados

- `WeaponControllerBase.gd` opcional futuro
- `GaiaInitialWeaponController.gd`
- `AttackHitbox2D.gd` como alvo futuro de consolidação
- `DirectionalAttackHitbox.gd` como base temporária reaproveitável

### Resources recomendados

- `WeaponDefinition`
- `AttackAreaDefinition`
- `DamageComponentDefinition`

### Signals usados

Locais:

- `attack_started`
- `attack_finished`
- `cooldown_changed(timer, total, ratio)`

Globais:

- `weapon_cooldown_changed`

### Layers/masks

- hitbox da Gaia:
  - layer 4 `PlayerAttackHitbox`
  - mask 5 `EnemyHurtbox`

### O que reaproveitar da base atual

- `GaiaInitialWeaponController.gd`
- `DirectionalAttackHitbox.gd`
- `WeaponDefinition`
- `GaiaAttackVisualController.gd`

### O que descartar

- duplicidade entre config de cena e config do `WeaponDefinition`
- múltiplas sources of truth para attack area

### Ordem de implementação

1. consolidar `WeaponDefinition` como fonte oficial
2. simplificar `GaiaInitialWeaponController`
3. convergir hitbox de ataque para contrato comum

---

## Sistema 8 - Inimigos

## Arquitetura alvo

### Nodes recomendados

`EnemyBase.tscn`

- `EnemyBase` (`CharacterBody2D`)
  - `BodyCollision` (`CollisionShape2D`)
  - `Hurtbox` (`Area2D`)
    - `CollisionShape2D`
  - `ContactAttackHitbox` (`Area2D`)
    - `CollisionShape2D`
  - `VisualRoot`
    - instância visual específica

Elites e bosses:

- cenas próprias herdando ou compondo a mesma base física/combat

### Scripts recomendados

- `EnemyBase.gd`
- `EnemyMovementComponent.gd`
- `EnemyCombatComponent.gd`
- `EnemyRewardComponent.gd`

### Resources recomendados

- `EnemyDefinition`
- `EnemyAttackDefinition`
- `HurtboxAreaDefinition`
- `AttackAreaDefinition`

### Signals usados

Locais:

- `target_changed(target)`
- `damage_received`
- `died(source_id)`

Globais:

- `enemy_damaged`
- `enemy_died`

### Layers/masks

- body:
  - layer 3 `EnemyBody`
  - mask 1 `World` e conforme necessidade física
- hurtbox:
  - layer 5 `EnemyHurtbox`
- ataque:
  - layer 6 `EnemyAttackHitbox`
  - mask 7 `PlayerHurtbox`

### O que reaproveitar da base atual

- `EnemyBase.gd`
- `EnemyAttackHitbox.gd`
- `EnemyDefinition`
- `enemy_chaser_basic.tres`
- visual do goblin

### O que descartar

- monólito único para tudo
- excesso de lógica de busca dinâmica para visual/target

### Ordem de implementação

1. manter `EnemyBase` funcional como baseline
2. extrair movement
3. extrair combat
4. extrair reward/death

---

## Sistema 9 - Spawn

## Arquitetura alvo

### Nodes recomendados

`EnemySpawner.tscn`

- `EnemySpawner` (`Node` ou `Node2D`)

Na cena da run:

- `SpawnerRoot`
  - 1 ou mais `EnemySpawner`

### Scripts recomendados

- `EnemySpawner.gd`
- `SpawnTimelineRuntime.gd` opcional futuro se a timeline crescer

### Resources recomendados

- `SpawnTimelineDefinition`
- `SpawnTimelineEntryDefinition`
- `MapDefinition`

### Signals usados

Locais:

- `enemy_spawned(enemy)`
- `wave_changed(entry_id)`

Globais:

- opcional nenhum obrigatório

### Layers/masks

- não aplica diretamente

### O que reaproveitar da base atual

- `EnemySpawner.gd`
- `EnemySpawner.tscn`
- timeline de spawn atual

### O que descartar

- dependência excessiva de grupos para descobrir player/root se a cena já pode injetar isso diretamente

### Ordem de implementação

1. manter spawner atual
2. tornar wiring explícito pela cena
3. preservar timeline e pooling

---

## Sistema 10 - Moeda física com magnetismo

## Arquitetura alvo

### Nodes recomendados

`CoinDrop.tscn`

- `CoinDrop` (`Node2D` ou `Area2D`)
  - `Visual` (`Sprite2D`)
  - `MagnetArea` (`Area2D`)
    - `CollisionShape2D`
  - `CollectArea` (`Area2D`)
    - `CollisionShape2D`

No player:

- `CollectArea`
- `MagnetArea`

ou, alternativamente, a moeda detecta diretamente `PlayerBody`.

### Scripts recomendados

- `CoinDrop.gd`
- `DropController.gd`

### Resources recomendados

- `CoinDropDefinition`

### Signals usados

Locais:

- `collected(value)`
- `magnetized(target)`

Globais:

- `run_coin_collected`
- `run_coins_changed`

### Layers/masks

Opção recomendada:

- `MagnetArea` e `CollectArea` usando detecção contra áreas do player
- layer 8 `DropPickup` reservado para esse ecossistema

Exemplo:

- áreas do player de coleta/magnetismo em layer 8
- moedas com mask 8 nas subáreas de trigger

ou o inverso, desde que padronizado.

### O que reaproveitar da base atual

- `CoinDropDefinition`
- `DropController`
- conceito de moeda física
- integração com run economy

### O que descartar

- complexidade desnecessária de magnetismo que não se apoie em áreas nativas

### Ordem de implementação

1. definir padrão de `MagnetArea` e `CollectArea`
2. refazer `CoinDrop.tscn`
3. religar `DropController`

---

## Sistema 11 - XP direta

## Arquitetura alvo

Há duas opções válidas.

### Opção A - XP instantânea, sem item físico

Quando o inimigo morre:

- XP entra direto no `RunController`

Uso:

- ideal para manter o protótipo simples

### Opção B - XP física coletável

`XpOrb.tscn`

- `Node2D` ou `Area2D`
  - `Visual`
  - `MagnetArea`
  - `CollectArea`

## Recomendação

Para a fase atual:

- manter XP direta
- moeda continua física

Isso reduz simultaneamente:

- clutter visual
- número de entidades
- complexidade de progressão

### Scripts recomendados

- nenhum novo se XP continuar direta

### Resources recomendados

- nenhum obrigatório

### Signals usados

Globais:

- `run_xp_changed`

### Layers/masks

- não aplica se XP for direta

### O que reaproveitar da base atual

- fluxo de XP atual via `RunController`

### O que descartar

- nada por enquanto

### Ordem de implementação

1. manter XP direta
2. só criar XP física quando houver necessidade de design real

---

## Sistema 12 - Level-up

## Arquitetura alvo

### Nodes recomendados

- `LevelUpPanel` (`CanvasLayer`)

### Scripts recomendados

- `LevelUpPanel.gd`
- `LevelUpOptionService.gd`
- `RunController.gd` como orquestrador do momento de level-up

### Resources recomendados

- `UpgradePoolDefinition`
- `UpgradeDefinition`

### Signals usados

Globais:

- `run_level_up_started(current_level, options)`
- `run_level_up_option_selected(upgrade)`
- `run_level_up_completed(current_level, selected_upgrade_id)`

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- `LevelUpPanel.gd`
- `LevelUpPanel.tscn`
- `LevelUpOptionService.gd`
- `UpgradePoolDefinition`

### O que descartar

- dependência de `find_child` recursivo
- hardcode estrutural excessivo do painel

### Ordem de implementação

1. manter fluxo atual
2. limpar painel
3. integrar com novo applier de upgrades

---

## Sistema 13 - Upgrades

## Arquitetura alvo

### Nodes recomendados

- nenhum node obrigatório novo
- pode ser um script auxiliar puro ou `Node` dentro de `RuntimeRoot`

### Scripts recomendados

- `RunUpgradeApplier.gd`
- `LevelUpOptionService.gd`
- handlers locais por domínio se necessário

### Resources recomendados

- `UpgradeDefinition`
- `UpgradePoolDefinition`
- `WeaponDefinition`
- `QueenDefinition`

### Signals usados

Globais:

- `run_level_up_option_selected`
- `run_level_up_completed`

Locais:

- `upgrade_applied(upgrade_id, target_type)`

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- `UpgradeDefinition`
- `UpgradePoolDefinition`
- `LevelUpOptionService`
- parte da lógica existente em player/weapon

### O que descartar

- aplicação espalhada em vários scripts como padrão definitivo

### Ordem de implementação

1. mapear categorias de upgrade
2. criar applier central
3. mover player/weapon upgrades para handlers
4. deixar `RunController` só coordenar

---

## Sistema 14 - Resultado

## Arquitetura alvo

### Nodes recomendados

- `ResultPanel` (`CanvasLayer`)

### Scripts recomendados

- `ResultPanel.gd`
- `RunController.gd`
- `RewardResolver.gd`

### Resources recomendados

- `RunResultPayload.gd`
- `MapDefinition`

### Signals usados

Globais:

- `run_finished(result_payload)`
- `run_result_persisted(result_payload, save_data, succeeded)`

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- `ResultPanel`
- `RunResultPayload`
- `RewardResolver`
- fluxo de vitória/derrota do `RunController`

### O que descartar

- nada estrutural importante

### Ordem de implementação

1. preservar o fluxo atual
2. simplificar `RunController`
3. garantir que `ResultPanel` continue passivo

---

## Sistema 15 - Save

## Arquitetura alvo

### Nodes recomendados

- `SaveManager` como autoload

### Scripts recomendados

- `SaveManager.gd`
- `SaveData.gd`

### Resources recomendados

- `SaveData` como `Resource` exportável

Campos recomendados:

- `total_xp`
- `total_money`
- `completed_maps`
- `last_run_summary`
- `basic_records`
- `settings`
- `purchased_upgrades`

### Signals usados

Globais:

- `save_updated(save_data)`
- `run_result_persisted(result_payload, save_data, succeeded)`

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- `SaveManager`
- `SaveData`
- schema geral do save

### O que descartar

- JSON manual como solução definitiva, se a serialização nativa atender

### Ordem de implementação

1. manter save atual no baseline
2. migrar `SaveData` para `@export`
3. trocar backend de serialização quando o core estabilizar

---

## Sistema 16 - UI

## Arquitetura alvo

### Nodes recomendados

`UiRoot`

- `RunHud` (`CanvasLayer`)
- `LevelUpPanel` (`CanvasLayer`)
- `ResultPanel` (`CanvasLayer`)
- `WorldFeedbackLayer` (`CanvasLayer`)
- `RunFeedbackLayer` opcional

Separado:

`DebugRoot`

- `DebugOverlay`
- `PrototypeToolsPanel`

### Scripts recomendados

- `RunHud.gd`
- `LevelUpPanel.gd`
- `ResultPanel.gd`
- `WorldFeedbackLayer.gd`
- `FloatingCombatText.gd`

### Resources recomendados

- nenhum obrigatório

### Signals usados

HUD:

- `player_damaged`
- `run_xp_changed`
- `run_enemy_killed`
- `run_coins_changed`
- `run_timer_changed`
- `weapon_cooldown_changed`

Panels:

- `run_level_up_started`
- `run_level_up_completed`
- `run_finished`
- `run_result_persisted`

### Layers/masks

- UI usa `CanvasLayer`, não physics layers

### O que reaproveitar da base atual

- `RunHud`
- `LevelUpPanel`
- `ResultPanel`
- `WorldFeedbackLayer`
- `FloatingCombatText`

### O que descartar

- HUD lendo `get_debug_data()` como fonte principal
- UI técnica misturada obrigatoriamente com UI de jogo

### Ordem de implementação

1. separar `UiRoot` e `DebugRoot`
2. fazer `RunHud` trabalhar por sinais
3. manter painéis passivos

---

## Sistema 17 - Spine / visual

## Arquitetura alvo

### Nodes recomendados

Por entidade visual:

- `VisualRoot` (`Node2D`)
  - `SpineVisual` (`Node2D`)
    - `SpineSprite`
    - adapter/controller necessários

Player:

- `GaiaVisual.tscn`

Enemy:

- `GoblinWarriorVisual.tscn`

### Scripts recomendados

- `SpineVisualControllerBase.gd`
- `SpineAnimationAdapterBase.gd`
- `GaiaVisualController.gd`
- `GoblinWarriorVisualController.gd`

### Resources recomendados

- skeleton/atlas Spine
- paths de visual definidos nos resources de entidade

### Signals usados

Locais:

- `animation_changed(animation_name)` opcional local

Globais:

- `spine_animation_changed(animation_name)` apenas para debug/telemetria

### Layers/masks

- não aplica

### O que reaproveitar da base atual

- `SpineVisualControllerBase`
- `SpineAnimationAdapterBase`
- controllers Gaia/Goblin
- separação visual/gameplay

### O que descartar

- reflexão desnecessária para resolver adapter quando o node path já pode ser explícito
- subclasses vazias demais, se puderem ser absorvidas sem perder clareza

### Ordem de implementação

1. preservar o subsistema visual
2. tipar/resolver paths de forma mais explícita
3. só então simplificar adapters finos

---

## Sistema 18 - Signals globais alvo

## `GameEvents` deve concentrar somente

### Player

- `player_damaged`
- `player_died`

### Enemy

- `enemy_damaged`
- `enemy_died`

### Run

- `run_started`
- `run_xp_changed`
- `run_enemy_killed`
- `run_coin_collected`
- `run_coins_changed`
- `run_level_up_started`
- `run_level_up_option_selected`
- `run_level_up_completed`
- `run_timer_changed`
- `run_finished`

### Weapon/UI

- `weapon_cooldown_changed`

### Save

- `save_updated`
- `run_result_persisted`

### Debug

- `spine_animation_changed`

## Não usar `GameEvents` para

- wiring de cena local;
- comunicação interna entre player e seus próprios filhos;
- chamadas simples que já têm referência direta.

---

## Ordem geral de implementação da arquitetura alvo

## Fase 1

1. consolidar `RunScene`
2. separar `DebugRoot`
3. consolidar source of truth da arma/attack area

## Fase 2

1. mover input para `PlayerController`
2. simplificar `RunHud`
3. reestruturar moeda física com áreas nativas

## Fase 3

1. fatiar `PlayerController`
2. fatiar `EnemyBase`
3. fatiar `GaiaInitialWeaponController`
4. reduzir `RunController`

## Fase 4

1. centralizar aplicação de upgrades
2. simplificar `GameEvents`
3. explicitar wiring principal de cena

## Fase 5

1. ajustar save para backend mais idiomático
2. simplificar base Spine sem perder separação visual/gameplay
3. podar resíduos finais

---

## Resumo final

## O que essa arquitetura quer preservar

- conteúdo data-driven;
- combate com hitbox/hurtbox real;
- pooling;
- visual desacoplado;
- run e save separados;
- UI passiva.

## O que ela quer eliminar

- monólitos excessivos;
- autoload de input;
- source of truth duplicada;
- wiring principal por grupo;
- debug misturado ao jogo final;
- abstrações próprias onde a Godot já entrega o suficiente.

## Resultado esperado

Uma base Godot 4.x que:

- continue modular;
- seja mais fácil de manter;
- fique mais barata de expandir;
- permaneça compatível com survivor-like data-driven;
- não brigue com o editor e com os fluxos nativos da engine.
