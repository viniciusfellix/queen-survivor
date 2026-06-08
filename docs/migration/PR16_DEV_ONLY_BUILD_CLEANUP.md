# PR16 - Dev-Only Build Cleanup

## Objetivo

Auditar ferramentas técnicas, painéis de debug, debug draw e canais de log para preparar uma execução mais limpa por padrão, sem remover ferramentas úteis e sem alterar gameplay.

Esta PR mantém os tools de desenvolvimento disponíveis, mas reduz defaults ruidosos e visuais técnicos que não precisam nascer ativos.

## Ferramentas técnicas encontradas

### Autoloads / Core técnico

- `res://autoloads/DeveloperAuditLogger.gd`
- `res://core/constants/DeveloperLogChannels.gd`
- `res://core/debug/RuntimeTreeSnapshot.gd`

### UI / overlays / painéis

- `res://ui/debug/DebugOverlay.gd`
- `res://ui/debug/DebugEnemyLinkDrawer.gd`
- `res://ui/debug/tools/PrototypeToolsPanel.gd`

### Cenas de composição

- `res://scenes/run/RunScene.tscn`
- `res://gameplay/test/TestGaiaScene.tscn` (legado/referência)

### Scripts com flags de debug/log auditados

- `res://gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `res://gameplay/combat/EnemyAttackHitbox.gd`
- `res://gameplay/drops/CoinDrop.gd`
- `res://gameplay/enemies/EnemyBase.gd`
- `res://gameplay/player/PlayerController.gd`
- `res://gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `res://visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `res://visual/enemies/goblin_warrior/GoblinWarriorVisualController.gd`
- `res://visual/spine/SpineAnimationAdapterBase.gd`
- `res://visual/spine/SpineVisualControllerBase.gd`
- `res://ui/hud/RunHud.gd`
- `res://gameplay/run/RunController.gd`
- `res://gameplay/spawners/EnemySpawner.gd`
- `res://gameplay/drops/DropController.gd`

## Estado atual dos canais de log

`DeveloperAuditLogger` já estava com defaults bons no nível global:

- ligado por padrão:
  - `LIFECYCLE`
- desligados por padrão:
  - `SCENE`
  - `SPAWN`
  - `COMBAT`
  - `ANIMATION`
  - `UPGRADE`
  - `SAVE`
  - `UI`
  - `SIGNAL`
  - `AUDIT`

Isso significa que chamadas de `DeveloperAuditLogger.log_*()` continuam no código, mas não poluem o console por padrão quando o canal está desligado.

## Ajustes aplicados nesta PR

### 1. DebugOverlay desligado por padrão no script base

Arquivo:

- `res://ui/debug/DebugOverlay.gd`

Mudança:

- `debug_enabled` passou de `true` para `false`.

Motivo:

- o overlay técnico não deve nascer ativo por padrão em cenas novas ou instâncias futuras;
- `RunScene` e `TestGaiaScene` já sobrescreviam isso para `false`, então a mudança alinha o script base ao uso real.

### 2. CoinDrop sem debug draw por padrão

Arquivo:

- `res://gameplay/drops/CoinDrop.gd`

Mudança:

- `draw_debug_visual` passou de `true` para `false`.

Motivo:

- moeda é objeto potencialmente numeroso;
- desenhar círculos/arcos de debug por padrão não faz sentido em execução normal.

### 3. EnemySpawner silencioso por padrão

Arquivo:

- `res://gameplay/spawners/EnemySpawner.gd`

Mudanças:

- `log_spawn_distance` passou de `true` para `false`;
- `log_timeline_changes` passou de `true` para `false`.

Motivo:

- spawn é sistema frequente e pode gerar volume alto de logs;
- os canais já estavam desligados globalmente, mas esses flags locais agora também nascem em estado coerente com build limpa/dev-only.

### 4. Logs de Spine/visual desligados por padrão no nível local

Arquivos:

- `res://visual/spine/SpineAnimationAdapterBase.gd`
- `res://visual/spine/SpineVisualControllerBase.gd`

Mudanças:

- `log_ready_status` passou de `true` para `false`;
- `log_visual_state_changes` passou de `true` para `false`.

Motivo:

- reduz trabalho desnecessário de logging visual em inicialização e troca de animação;
- combina melhor com o fato de o canal `ANIMATION` já nascer desligado.

## O que permanece disponível em desenvolvimento

### DebugOverlay

- continua presente em `RunScene` dentro de `DebugRoot`;
- continua podendo ser habilitado manualmente;
- continua suportando `DebugEnemyLinkDrawer`.

### PrototypeToolsPanel

- continua presente em `RunScene` dentro de `DebugRoot`;
- continua invisível no start;
- continua usando:
  - `F3` para abrir/fechar;
  - `F4` para exportar snapshot runtime.

### RuntimeTreeSnapshot

- continua funcionando como utilitário técnico;
- continua imprimindo o snapshot no console quando disparado explicitamente pelo `F4`.

### Force victory / force defeat

- `RunController.gd` continua com `allow_debug_force_finish = false` no script base;
- `RunScene.tscn` e `TestGaiaScene.tscn` ainda sobrescrevem isso para `true`, preservando fluxo de desenvolvimento atual.

Observação importante:

- isso ainda é uma convenção de cena de desenvolvimento, não um sistema formal de build mode;
- uma PR futura pode separar melhor “scene de dev” e “build limpa” sem tocar no runtime principal.

## O que deve estar desligado em build limpa

Sem criar um sistema global novo nesta PR, a recomendação de baseline limpa fica:

- `DebugOverlay.debug_enabled = false`
- `DebugEnemyLinkDrawer.links_enabled = false`
- `PrototypeToolsPanel.visible_on_start = false`
- `CoinDrop.draw_debug_visual = false`
- `PlayerController.draw_debug_aim = false`
- `EnemyBase.draw_debug_visual = false`
- `EnemyBase.draw_debug_target_line = false`
- `DirectionalAttackHitbox.draw_debug_hitbox = false`
- `EnemySpawner.log_spawn_distance = false`
- `EnemySpawner.log_timeline_changes = false`
- `SpineAnimationAdapterBase.log_ready_status = false`
- `SpineAnimationAdapterBase.log_animation_changes = false`
- `SpineVisualControllerBase.log_visual_state_changes = false`
- canais globais verbosos do `DeveloperAuditLogger` desligados

## Como habilitar logs por canal

Em desenvolvimento, os canais podem ser reativados via `DeveloperAuditLogger`:

```gdscript
DeveloperAuditLogger.set_channel_enabled(DeveloperLogChannels.COMBAT, true)
DeveloperAuditLogger.set_channel_enabled(DeveloperLogChannels.SPAWN, true)
DeveloperAuditLogger.set_channel_enabled(DeveloperLogChannels.ANIMATION, true)
```

Resumo do estado atual:

- o logger continua apto a registrar tudo;
- o projeto só não imprime/captura canais verbosos por padrão.

## Como usar F3 / F4 em desenvolvimento

- `F3`: abre/fecha `PrototypeToolsPanel`
- `F4`: exporta snapshot runtime e copia para a área de transferência

Esses atalhos permanecem ativos para desenvolvimento e QA. Esta PR não removeu esse fluxo.

## Arquivos alterados

- `res://ui/debug/DebugOverlay.gd`
- `res://gameplay/drops/CoinDrop.gd`
- `res://gameplay/spawners/EnemySpawner.gd`
- `res://visual/spine/SpineAnimationAdapterBase.gd`
- `res://visual/spine/SpineVisualControllerBase.gd`

## O que ficou para futuro

- formalizar um `dev mode` ou `build mode` explícito, em vez de depender apenas de defaults/export flags por script/cena;
- decidir se `allow_debug_force_finish` deve permanecer `true` na `RunScene` de desenvolvimento ou migrar para uma cena/dev preset separado;
- avaliar se `DebugOverlay` deve ganhar um contrato explícito para “dormir” totalmente quando desligado e ser reativado por API, sem depender de polling leve;
- revisar `print()` intencional do snapshot runtime para um fluxo mais controlado de export técnico, se isso fizer sentido depois.

## Confirmações

- gameplay não foi alterado;
- balanceamento não foi alterado;
- `save`, `reward` e `result` não foram alterados.

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar pelo play principal.
4. Confirmar que `RunScene` carrega.
5. Confirmar:
   - Gaia move;
   - dash;
   - ataque da Gaia;
   - Goblins spawnam, perseguem, causam dano e morrem;
   - XP, moeda, level-up, upgrades, vitória/derrota/result/save.
6. Confirmar que o console não fica poluído com logs de `COMBAT`, `SPAWN` ou `ANIMATION` por padrão.
7. Confirmar `DebugOverlay` quando habilitado manualmente.
8. Confirmar `PrototypeToolsPanel` com `F3`.
9. Confirmar `RuntimeTreeSnapshot` com `F4`.
10. Confirmar que debug tools não alteram gameplay.
11. Confirmar console sem erro novo.

## Riscos conhecidos

- `RunScene.tscn` ainda mantém `allow_debug_force_finish = true` como convenção de desenvolvimento;
- `PrototypeToolsPanel` continua disponível por atalho em runtime dev, o que é desejado para QA local, mas ainda não separado por preset/export;
- `RuntimeTreeSnapshot` ainda usa `print()` por escolha intencional quando o usuário aciona `F4`.
