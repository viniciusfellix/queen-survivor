# PR11 - Enemy Lifecycle Pooling Audit

## Objetivo da PR

Auditar o lifecycle de inimigos e spawn, identificar se a base atual ja esta pronta para pooling seguro e aplicar apenas saneamentos pequenos que nao alterem gameplay.

## Por que inimigos sao mais arriscados que hitbox/texto/moeda

Pooling de inimigo e mais delicado porque a instancia carrega estado de varios subsistemas ao mesmo tempo:

- HP e estado vivo/morto;
- movement/physics de `CharacterBody2D`;
- hurtbox;
- attack hitbox;
- knockback recebido;
- body bump e player body slide;
- visual/animacao de morte;
- grupos (`enemy`);
- sinais globais (`enemy_died`);
- XP e drop;
- referencia ao player;
- delay de morte antes do despawn.

Em outras palavras: reutilizar um inimigo com estado sujo pode gerar bugs mais graves do que reutilizar um texto flutuante ou um visual temporario.

## Arquivos inspecionados

- `autoloads/PoolManager.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/enemies/EnemyBase.tscn`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/combat/HurtboxComponent.gd`
- `definitions/EnemyAttackDefinition.gd`
- `definitions/EnemyDefinition.gd`
- `definitions/HurtboxAreaDefinition.gd`
- `definitions/SpawnTimelineDefinition.gd`
- `definitions/SpawnTimelineEntryDefinition.gd`
- `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `gameplay/run/RunController.gd`
- `gameplay/drops/DropController.gd`
- `autoloads/GameEvents.gd`

## Fluxo atual de spawn

1. `EnemySpawner._process()` conta tempo e consulta timeline ativa.
2. Quando pode spawnar, chama `force_spawn_enemy()`.
3. `EnemySpawner` calcula uma posicao segura ao redor da Gaia.
4. O inimigo e adquirido via `PoolManager.spawn_path(enemy_scene_path, enemy_root, spawn_position)`.
5. O node reutilizado ou novo recebe `setup(enemy_definition, player_node)`.
6. `EnemyBase.setup()` aplica `EnemyDefinition`, resolve visual e atualiza estado.
7. `EnemySpawner` incrementa `_alive_enemy_count`.

Resumo: **spawn de inimigo ja usa `PoolManager` hoje**. Nao ha `instantiate()` direto no hot path do spawner.

## Fluxo atual de morte

1. `EnemyBase.receive_damage()` reduz HP.
2. Quando HP chega a zero, chama `die(source_id)`.
3. `die()`:
   - marca `is_alive = false`;
   - zera velocidades;
   - desliga hurtbox;
   - desliga `EnemyAttackHitbox`;
   - emite `GameEvents.enemy_died(...)`;
   - atualiza visual de morte;
   - remove do grupo `enemy`;
   - agenda um `SceneTreeTimer` para despawn apos `remove_after_death_seconds`.
4. Quando o timer vence, `EnemyBase` chama `PoolManager.despawn(self)`.

Resumo: **morte usa delay visual curto e depois devolve ao pool**.

## Fluxo atual de XP e drop

- `RunController` escuta `GameEvents.enemy_died` e:
  - incrementa kills;
  - adiciona XP direta;
  - abre level-up quando necessario.
- `DropController` escuta o mesmo signal e:
  - avalia chance de drop;
  - cria moeda fisica no mundo se o roll passar.

Importante: XP e drop estao desacoplados do lifecycle interno do inimigo e continuam dependentes de `enemy_died` ser emitido **uma unica vez por morte**.

## Instantiate/queue_free ou PoolManager?

### EnemySpawner / EnemyBase

- Spawn: `PoolManager.spawn_path(...)`
- Despawn: `PoolManager.despawn(self)`

### EnemyAttackHitbox

- Nao e criada/destruida por ataque.
- Ela existe como child fixa da cena `EnemyBase.tscn`.
- O que muda em runtime e o `setup()` com `EnemyAttackDefinition` e a ativacao/desativacao.

### HurtboxComponent

- Tambem existe como child fixa da cena `EnemyBase.tscn`.
- As `CollisionShape2D` internas sao reconstruidas em runtime no `setup()`.

## Estado que precisa ser resetado para pooling futuro

Para pooling de inimigos ficar realmente robusto no futuro, o estado abaixo precisa estar sempre limpo:

- `is_alive`
- `current_hp` / `max_hp`
- `velocity`
- `body_bump_velocity`
- `player_body_slide_velocity`
- `received_knockback_velocity`
- `active_knockback_chase_weight`
- `target_node`
- `total_damage_taken`
- `last_damage_taken`
- `last_damage_source_id`
- grupo `enemy`
- hurtbox ativa/inativa
- contact attack hitbox ativa/inativa
- callbacks atrasados de timer de morte
- estado visual de morte / flash / animacao
- referencias duplicadas de signals globais

## Riscos de estado sujo encontrados

### 1. Timer de morte atrasado reaproveitando instancia

Risco real identificado:

- `EnemyBase.die()` criava um `SceneTreeTimer`;
- se a instancia fosse reutilizada e algum callback antigo sobrevivesse, poderia ocorrer `despawn` tardio em uma instancia ja respawnada.

Esse era o risco mais relevante de pooling encontrado nesta PR.

### 2. Inimigo morto ainda processando fisica durante o delay de morte

Antes desta PR, o inimigo morto ainda passava por `_physics_process()` ate o timer vencer. O codigo ja zerava velocidades e desligava combate, mas o processamento continuava rodando sem necessidade.

### 3. Release sem hook explicito

`EnemyBase` ja tinha `_on_pool_acquire()`, mas nao tinha `_on_pool_release()`. Isso deixava a limpeza de retorno ao pool menos explicita do que nos objetos temporarios que ja foram saneados em PRs anteriores.

## Pequenos saneamentos feitos

### EnemyBase.gd

1. Adicionado `death_despawn_token` para invalidar callbacks antigos de timer de morte.
2. `die()` agora:
   - incrementa o token de morte;
   - zera tambem `player_body_slide_velocity`;
   - desliga `physics_process` apos acionar visual de morte;
   - remove do grupo `enemy` apenas se ainda estiver no grupo;
   - conecta o timer de morte com validacao do token.
3. `_on_death_timer_timeout()` agora aborta se o inimigo ja voltou a estar vivo.
4. `_on_pool_acquire()` agora:
   - invalida timers antigos;
   - limpa `target_node`;
   - religa `physics_process`.
5. Adicionado `_on_pool_release()` para:
   - invalidar timers antigos;
   - marcar como nao vivo;
   - limpar target;
   - desligar `physics_process`;
   - zerar velocidades;
   - limpar telemetria;
   - desativar hurtbox e attack hitbox.

## O que ficou para PR futura

1. Pooling mais profundo de `EnemyAttackHitbox` e `HurtboxComponent` internos:
   - hoje eles continuam recriando `CollisionShape2D` runtime no `setup()`.
2. Reset visual explicito de Goblin/Spine no retorno ao pool:
   - a base atual depende de `EnemyBase._update_visual_state()` e da reconfiguracao normal.
   - funciona para o fluxo atual, mas merece auditoria propria se o volume de reuso aumentar.
3. Rever uso de reflexao em `EnemyBase` (`has_method` / `call`) no body bump hot path.
4. Considerar substituir `SceneTreeTimer` por controle interno de despawn se profiling mostrar custo relevante em hordas muito grandes.

## Recomendacao final

**Nao implementar pooling completo de inimigos nesta PR.**

Motivo:

- o projeto ja usa `PoolManager` no spawn/despawn de inimigos;
- a base ja esta parcialmente preparada;
- o maior ganho imediato nesta fase era endurecer lifecycle e invalidar estado atrasado;
- pooling completo de inimigos ainda exigiria auditoria mais profunda de:
  - visual/Spine;
  - `EnemyAttackHitbox`;
  - `HurtboxComponent`;
  - recriacao de shapes runtime;
  - possiveis custos de timer e logs.

Conclusao: **implementar depois, em PR dedicada**, partindo desta base saneada.

## Checklist de testes

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar o jogo pelo play principal.
4. Confirmar que `RunScene` carrega.
5. Confirmar que Goblins spawnam.
6. Confirmar que Goblins perseguem a Gaia.
7. Confirmar que Goblins causam dano.
8. Confirmar que Goblins recebem dano.
9. Confirmar que Goblins morrem.
10. Confirmar que `enemy_died` nao duplica.
11. Confirmar que XP entra direto.
12. Confirmar que moeda dropa.
13. Confirmar que moeda magnetiza/coleta.
14. Confirmar que Goblin morto nao continua causando dano.
15. Confirmar que visual de morte funciona.
16. Confirmar que ataque da Gaia continua funcionando.
17. Confirmar que dash continua funcionando.
18. Confirmar que level-up/upgrades continuam funcionando.
19. Confirmar vitoria/derrota/result/save.
20. Testar alguns minutos com varios Goblins.
21. Confirmar console sem erro novo.
22. Confirmar que logs verbosos nao ficaram ligados por padrao.
