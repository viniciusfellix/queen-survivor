# AUDIT 04 - Godot Native Refactor Plan

## Princípio orientador

Regra para a migração:

> usar a solução nativa da Godot primeiro; abstrair só quando a repetição for real, recorrente e reduzir complexidade de runtime ou de edição.

## 1. Estrutura de cena e composition root

## Problema

`TestGaiaScene.tscn` virou a cena principal real, mas continua sendo “cena de teste”.

## Solução Godot idiomática

Criar uma cena composition root explícita de gameplay, por exemplo:

- `scenes/run/RunScene.tscn`

Estrutura sugerida:

- `RunScene` (`Node2D`)
  - `ArenaRoot`
  - `RuntimeRoot`
    - `PlayerRoot`
    - `EnemyRoot`
    - `DropRoot`
    - `SpawnerRoot`
    - `RunController`
    - `DropController`
  - `Camera2D`
  - `UiRoot`
    - `RunHud`
    - `LevelUpPanel`
    - `ResultPanel`
    - `WorldFeedbackLayer`
    - `RunFeedbackLayer`
  - `DebugRoot` (carregado só em debug ou por flag)

## O que simplifica

- separa UI técnica de UI de jogo;
- tira o peso semântico de “test” do core;
- deixa claro o wiring principal do runtime.

## 2. Input

## Problema

`InputManager` global para um único player local.

## Solução Godot idiomática

Ler input direto no `PlayerController`:

```gdscript
var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
var dash_pressed := Input.is_action_just_pressed("dash")
```

Para mouse:

- `get_global_mouse_position()` no próprio player

Para analógico direito:

- `Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")`
- `Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")`

## O que manter

- Input Map no `project.godot`

## O que remover conceitualmente

- estado global de input compartilhado;
- dependência temporal de “alguém atualizou o manager neste frame”.

## 3. Hitbox, Hurtbox e dano

## O que manter

- `Area2D` para hitbox
- `Area2D` para hurtbox
- `CollisionShape2D`
- `DamagePayload`
- `DamageResolver`
- layers/masks atuais

## O que simplificar

### Hurtbox

Quando a hurtbox for estática para uma entidade:

- preferir shapes já presentes na cena
- usar resource só para dados que realmente precisam ser data-driven

Quando precisar ser realmente data-driven:

- `HurtboxComponent` pode seguir montando runtime shapes

### Hitbox ofensiva

Criar um contrato comum conceitual:

- `AttackHitbox2D`

Configuração:

- `source_node`
- `source_id`
- `DamagePayload` ou dados para montá-lo
- tempo de vida
- política de hit único ou multi-hit
- knockback opcional

Pode ser base de:

- ataque melee
- dash ofensivo
- projétil que explode em área

### Fluxo ideal

1. arma/inimigo/dash ativa uma `Area2D` ofensiva;
2. `area_entered` e uma checagem inicial de overlaps cobrem o frame de ativação;
3. se a área detectada é `HurtboxComponent`, resolve o receiver;
4. entrega `DamagePayload`;
5. receiver aplica HP/efeitos;
6. knockback é aplicado como efeito pós-hit, não embutido na colisão física.

## 4. Player

## Estrutura sugerida

`PlayerGaia.tscn`

- `CharacterBody2D` root
  - `BodyCollision`
  - `PlayerHurtbox`
  - `DashImpactArea`
  - `VisualRoot/GaiaVisual`
  - `WeaponRoot`

## Scripting sugerido

### `PlayerController.gd`

Fica responsável por:

- input;
- movimento;
- vida;
- início/fim de dash;
- `receive_damage`;
- coordenação com arma/visual.

### `PlayerDashComponent.gd` ou equivalente local

Fica responsável por:

- cooldown;
- duração;
- cálculo de direção;
- regras de colisão durante dash;
- integração com `DashImpactArea`.

### `PlayerStatsRuntime.gd` opcional

Se o runtime state continuar, que fique restrito a:

- HP;
- move speed;
- defense;
- multiplicadores;
- flags de vida/invulnerabilidade.

Evitar que ele vire espelho de todo input/visual.

## 5. Inimigos

## Estrutura base sugerida

`EnemyBase.tscn`

- `CharacterBody2D`
  - `BodyCollision`
  - `Hurtbox`
  - `AttackHitbox`
  - `VisualRoot`

## Separação profissional sugerida

### `EnemyBase.gd`

Coordena:

- definition;
- target;
- vida;
- morte;
- comunicação com visual.

### `EnemyMovementComponent.gd`

Executa:

- chase;
- stopping distance;
- body bump;
- slide;
- blend com knockback.

### `EnemyCombatComponent.gd`

Executa:

- setup do ataque;
- ligação da hurtbox;
- aplicação de dano recebido;
- telemetria local de combate.

### `EnemyRewardComponent.gd`

Executa:

- XP;
- coin chance/value;
- emissão de morte.

## Benefício

Isso permite futuramente:

- inimigo comum: movimento + combate simples
- elite: movimento comum + combate custom
- miniboss: combate e states próprios
- boss: cena e AI próprias sem depender de um `EnemyBase.gd` monolítico

## 6. Moedas, drops e magnetismo

## Solução Godot idiomática recomendada

### Estrutura de cena

`CoinDrop.tscn`

- `Area2D` root ou `Node2D` root
  - `Sprite2D`
  - `CollectArea` (`Area2D`)
    - `CollisionShape2D`
  - `MagnetArea` (`Area2D`)
    - `CollisionShape2D`

## Layers/masks sugeridas

Manter layer 8 para coleta/drop.

Opções:

### Opção A

- player tem uma `PlayerCollectArea`
- moeda detecta essa área

### Opção B

- moeda usa `Area2D` com mask voltada para `PlayerBody`

Prefiro `PlayerCollectArea` porque separa:

- corpo físico
- raio de coleta

### Fluxo

1. `MagnetArea.area_entered/body_entered` liga `is_magnetized`;
2. enquanto magnetizada, moeda faz steering simples até o player;
3. `CollectArea` detecta `PlayerCollectArea`;
4. coleta;
5. emite evento ou chama o fluxo de economia.

## Benefício

- menos lógica implícita;
- mais previsível no editor;
- fácil de visualizar com visible collision shapes;
- preparado para drops futuros.

## 7. Upgrades

## Problema

Aplicação de upgrade espalhada.

## Solução nativa/idiomática

Criar um applier central com handlers específicos, por exemplo:

- `RunUpgradeApplier.gd`

Entradas:

- `UpgradeDefinition`
- referências principais da run

Saídas:

- aplica no alvo correto

Handlers:

- `apply_to_player(upgrade)`
- `apply_to_weapon(upgrade)`
- `apply_to_collection(upgrade)`
- `apply_to_run(upgrade)`

## Benefício

- `RunController` deixa de ser orquestrador + aplicador;
- `PlayerController` e `GaiaInitialWeaponController` deixam de conhecer a matriz inteira de upgrades;
- fica muito mais fácil suportar:
  - armas múltiplas;
  - passivos;
  - reroll;
  - banish;
  - blocos por categoria.

## 8. Save

## Situação

JSON manual sobre `SaveData` que já é `Resource`.

## Solução realista

Migrar para:

- `ResourceSaver.save(save_data, "user://save.tres")`
- `ResourceLoader.load("user://save.tres")`

Ou `.res`, conforme necessidade.

## Estrutura sugerida

`SaveData` exportado com:

- `@export var total_xp`
- `@export var total_money`
- `@export var completed_maps`
- `@export var last_run_summary`
- `@export var basic_records`
- `@export var settings`
- `@export var purchased_upgrades`

## O que não fazer agora

- criptografia sofisticada
- múltiplos profiles
- migration framework pesado

## 9. UI

## RunHud

### Problema

Polling e dependência de `get_debug_data()`.

### Solução

Atualizar por sinais reais:

- `player_damaged`
- `run_xp_changed`
- `run_coins_changed`
- `run_enemy_killed`
- `run_timer_changed`
- `weapon_cooldown_changed`
- evento inicial de sync no `_ready`

O HUD deve ler snapshots iniciais mínimos e depois trabalhar por sinal.

## Debug UI

`DebugOverlay` e `PrototypeToolsPanel` devem:

- ficar em `DebugRoot`;
- ser carregados só em debug;
- não contaminar o composition root principal do jogo final.

## 10. Spine

## O que manter

- `SpineVisualControllerBase`
- `SpineAnimationAdapterBase`
- controllers específicos por personagem

## O que simplificar

- menos busca dinâmica de adapter;
- menos reflexão via `call`;
- adapters triviais podem virar configuração na base;
- manter track 0 como base e track 1+ para overlays, como blink.

## 11. Logs e ferramentas

## Princípio

Ferramenta de debug não deve definir arquitetura do runtime.

## Regra sugerida

- `DeveloperAuditLogger` ligado só em debug
- `DebugOverlay` e `PrototypeToolsPanel` só em debug path
- `RuntimeTreeSnapshot` como tool/manual
- não deixar APIs de debug virarem dependência de HUD e gameplay comum

## 12. Resultado esperado da refatoração nativa

Após a migração, a base ideal deve parecer:

- mais cenas configuradas no editor;
- menos resolução por grupo para wiring principal;
- menos `has_method`/`call` no caminho quente;
- mais `Area2D`/`CollisionShape2D` com responsabilidades diretas;
- `Resource` só onde realmente agrega edição e reuso;
- controllers menores e mais previsíveis.
