# PR12 - Enemy Pooled Reuse Hardening

## Objetivo da PR

Endurecer o reuso de inimigos pooled, focando em reset visual/Spine, `HurtboxComponent` e `EnemyAttackHitbox`, sem alterar balanceamento, spawn, dano, XP, drop, save, resultado ou comportamento percebido pelo jogador.

## Por que reset de inimigo pooled e critico

O projeto ja usa `PoolManager` para inimigos. Isso significa que o risco principal nao e mais "instanciar demais", e sim **reutilizar uma instancia com estado velho**.

Se esse reset falhar, um Goblin pode reaparecer com:

- animacao de morte ainda ativa;
- flash visual antigo;
- hurtbox indevidamente desativada;
- attack hitbox com receivers/cooldowns antigos;
- target antigo;
- estado de knockback antigo;
- grupo `enemy` errado;
- callback de morte antigo.

## Arquivos inspecionados

- `gameplay/enemies/EnemyBase.gd`
- `gameplay/enemies/EnemyBase.tscn`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/combat/HurtboxComponent.gd`
- `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `visual/enemies/goblin_warrior/GoblinWarriorSpineAdapter.gd`
- `visual/spine/SpineAnimationAdapterBase.gd`
- `visual/spine/SpineVisualControllerBase.gd`
- `definitions/EnemyDefinition.gd`
- `definitions/EnemyAttackDefinition.gd`
- `definitions/HurtboxAreaDefinition.gd`

## Arquivos alterados

- `gameplay/enemies/EnemyBase.gd`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/combat/HurtboxComponent.gd`
- `visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `visual/spine/SpineAnimationAdapterBase.gd`

## Como EnemyBase ficou protegido

- `EnemyBase._on_pool_acquire()` agora:
  - reseta `visual_chase_direction`;
  - continua religando `physics_process`;
  - chama reset explicito do visual pooled via `_reset_visual_for_pool_reuse()`.
- `EnemyBase._on_pool_release()` agora:
  - reseta `visual_chase_direction`;
  - continua desligando combate/physics;
  - chama `_deactivate_visual_for_pool()`.
- O inimigo continua:
  - reentrando no grupo `enemy` ao voltar vivo;
  - invalidando timers antigos de morte;
  - mantendo `enemy_died` emitido uma unica vez por morte.

## Como EnemyAttackHitbox ficou protegido

- ganhou hooks `_on_pool_acquire()` e `_on_pool_release()`;
- ganhou `reset_runtime_state()`;
- ganhou `clear_tracked_receivers()`;
- limpa explicitamente:
  - `receiver_cooldowns`;
  - `overlapping_hurtboxes`;
  - `elapsed_seconds`;
  - `source_node`;
  - `source_id`;
  - `runtime_definition`;
  - `is_configured`;
- desliga `monitoring` quando inativa;
- nao carrega cooldown ou receiver de um uso anterior do inimigo.

## Como HurtboxComponent ficou protegido

- ganhou hooks `_on_pool_acquire()` e `_on_pool_release()`;
- limpa `damage_receiver`;
- entra em estado inerte ate o `setup()` do proximo uso;
- continua reativando corretamente no `setup()` de `EnemyBase`.

## Como o visual/Spine do Goblin ficou protegido

### GoblinWarriorVisualController

- ganhou `reset_visual_state()`;
- ganhou `deactivate_for_pool()`;
- ganhou helper `_stop_damage_flash_tween()`;
- mata tween antigo de flash;
- restaura `modulate`;
- limpa estado visual base:
  - `current_animation_name`
  - `current_visual_state`
  - `current_animation_time_scale`
- restaura escala sem flip residual indevido.

### SpineAnimationAdapterBase

- ganhou `reset_adapter_state()`;
- limpa tracks conhecidas;
- limpa cache interno de animacoes/track/time scale;
- ajuda a evitar que o proximo spawn herde estado de death/overlay antigo.

## O que nao foi alterado

- HP
- velocidade
- dano
- XP
- moeda
- cooldown
- knockback
- defesa
- fraquezas/resistencias
- timeline de spawn
- quantidade de inimigos
- nomes de animacoes
- fluxo de `enemy_died`
- save/result/reward

## Testes manuais necessarios

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar o jogo pelo play principal.
4. Confirmar `RunScene`.
5. Confirmar que Goblins spawnam.
6. Confirmar que Goblins perseguem a Gaia.
7. Confirmar que Goblins causam dano.
8. Confirmar que Goblins recebem dano.
9. Confirmar que Goblins morrem.
10. Confirmar animacao/visual de morte.
11. Confirmar que `enemy_died` nao duplica.
12. Confirmar XP direta.
13. Confirmar drop de moeda.
14. Confirmar que Goblin morto nao continua causando dano.
15. Esperar novos Goblins reutilizados pelo pool.
16. Confirmar que Goblin reutilizado:
   - aparece vivo;
   - nao aparece travado em death;
   - nao aparece com flash antigo;
   - volta a perseguir;
   - volta a causar dano;
   - volta a receber dano;
   - morre normalmente de novo.
17. Testar alguns minutos com varios Goblins.
18. Confirmar ataque da Gaia, dash, moeda, XP, level-up, upgrades, vitoria, derrota, result e save.
19. Confirmar console sem erro novo.

## Riscos conhecidos

- `EnemyAttackHitbox` e `HurtboxComponent` ainda recriam `CollisionShape2D` runtime em `setup()`; esta PR so endurece reset/lifecycle, nao faz cache/pooling de shapes.
- O visual Spine foi saneado no nivel de controller/adapter, mas uma futura PR ainda pode revisar em mais profundidade algum estado especifico de plugin Spine, se aparecer comportamento residual em profiling real.

## Proximos passos

1. Auditar se vale cachear/reutilizar shapes internas de `EnemyAttackHitbox` e `HurtboxComponent`.
2. Reduzir `has_method/call` no hot path de `EnemyBase` em PR propria.
3. Revisar pooling de inimigos em lote sob profiling com hordas maiores.
