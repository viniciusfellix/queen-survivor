# PR15 - Hot Path Contracts

## Objetivo

Reduzir chamadas dinâmicas desnecessárias em hot paths de gameplay, substituindo `has_method()`, `call()` e lookups repetidos por referências mais explícitas e contratos cacheados quando isso pudesse ser feito com baixo risco.

Esta PR não muda regras de gameplay, balanceamento, save, reward, result, UI visual ou fluxo oficial de runtime.

## Arquivos inspecionados

- `gameplay/enemies/EnemyBase.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/player/PlayerDashImpactArea.gd`
- `gameplay/combat/HurtboxComponent.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/run/RunController.gd`
- `ui/debug/DebugOverlay.gd`
- `ui/debug/DebugEnemyLinkDrawer.gd`
- `ui/hud/RunHud.gd`
- `visual/spine/SpineVisualControllerBase.gd`
- `visual/spine/SpineAnimationAdapterBase.gd`

## Hot paths relevantes encontrados

### Crítico

| Arquivo | Hot path | Situação encontrada | Ação |
| --- | --- | --- | --- |
| `gameplay/combat/HurtboxComponent.gd` | checagem frequente antes de aplicar dano | `can_receive_damage()` chamava `damage_receiver.has_method("receive_damage")` toda vez | Ajustado nesta PR com cache do contrato |
| `gameplay/enemies/EnemyBase.gd` | `_physics_process()` -> `_process_body_bump_collisions()` | body bump entre inimigos usava `has_method()` + `call()` para consultar vida e bump power do collider | Ajustado nesta PR com acesso tipado direto para `EnemyBase` |

### Já aceitável no hot path

| Arquivo | Observação |
| --- | --- |
| `gameplay/weapons/attacks/DirectionalAttackHitbox.gd` | fluxo principal já usa `HurtboxComponent` e `EnemyBase` tipados |
| `gameplay/combat/EnemyAttackHitbox.gd` | fluxo principal já usa `HurtboxComponent` e `PlayerController` tipados |
| `gameplay/player/PlayerDashImpactArea.gd` | fluxo de impacto do dash já usa casts diretos e contrato claro |
| `gameplay/drops/CoinDrop.gd` | após PR14, o movimento só roda quando magnetizada; lookup dinâmico restante não fica no loop de física contínuo |

### Moderado / fora do hot path crítico

| Arquivo | Situação encontrada | Decisão |
| --- | --- | --- |
| `gameplay/run/RunController.gd` | `has_method()/call()` ao aplicar upgrade no player | manter por enquanto; ocorre em evento, não por frame |
| `gameplay/spawners/EnemySpawner.gd` | `has_method()/call()` no setup do inimigo e lookup de player por grupo | manter; caminho de spawn, não loop crítico por frame |
| `gameplay/player/PlayerController.gd` | `has_method()/call()` em visual controller e upgrades de armas | manter; exigiria contrato mais amplo entre player, armas e visual |
| `ui/hud/RunHud.gd` | `get_nodes_in_group("player")` e `call("get_debug_data")` em refresh periódico | manter; HUD técnico/visual, não hot path de combate |

### Debug / tooling

| Arquivo | Situação encontrada | Decisão |
| --- | --- | --- |
| `ui/debug/DebugOverlay.gd` | grupo + `has_method()/call()` para debug data | manter; debug only |
| `ui/debug/DebugEnemyLinkDrawer.gd` | grupo + `has_method()/call()` por update de debug | manter; debug only |

### Abstração/integração externa

| Arquivo | Situação encontrada | Decisão |
| --- | --- | --- |
| `visual/spine/SpineVisualControllerBase.gd` | `has_method()/call()` para falar com adapter Spine | manter; compatibilidade entre adapter base e implementação concreta |
| `visual/spine/SpineAnimationAdapterBase.gd` | `has_method()/call()` para falar com runtime Spine | manter; integração dinâmica intencional |

## Ajustes aplicados

### 1. HurtboxComponent: cache do contrato de receiver

Antes:

- `can_receive_damage()` verificava `has_method("receive_damage")` a cada consulta.

Agora:

- o receiver é atualizado por `_set_damage_receiver()`;
- o contrato mínimo (`damage_receiver_can_receive_damage`) é cacheado fora do hot path;
- `can_receive_damage()` passa a fazer apenas checagem booleana simples e validade da instância.

Impacto:

- reduz reflexão dinâmica em todo fluxo de hitbox -> hurtbox -> receiver;
- preserva o fallback atual de resolver receiver por `NodePath` ou parent;
- não muda cálculo de dano nem ordem de eventos.

### 2. EnemyBase: body bump com acesso tipado direto

Antes:

- ao colidir com outro inimigo, o body bump consultava `is_enemy_alive()` e `get_body_bump_power()` via `has_method()` + `call()`.

Agora:

- quando o collider é `EnemyBase`, o acesso é direto e tipado;
- o fallback dinâmico continua existindo apenas para algum node incomum no grupo `enemy` que não seja `EnemyBase`.

Impacto:

- reduz reflexão dentro de `_process_body_bump_collisions()`, que roda dentro do `_physics_process()` dos inimigos;
- mantém compatibilidade defensiva com membros atípicos do grupo `enemy`;
- não altera força de bump, slide, knockback ou perseguição.

## O que ficou para futuro

### Candidatos bons para PR futura

- `RunHud.gd`: cachear referência do player e do run controller para evitar `get_nodes_in_group()`/`call()` em refresh periódico.
- `PlayerController.gd`: formalizar contrato do visual controller e das armas para reduzir `has_method()/call()` em upgrades e feedback visual.
- `EnemyBase.gd`: formalizar interface do visual controller para reduzir chamadas dinâmicas em `_update_visual_state()` e `_play_damage_feedback()`.
- `EnemySpawner.gd`: trocar setup dinâmico por contrato mais explícito quando a hierarquia de inimigos estiver estabilizada.

### Não priorizar agora

- `DebugOverlay.gd`
- `DebugEnemyLinkDrawer.gd`
- `SpineVisualControllerBase.gd`
- `SpineAnimationAdapterBase.gd`

Nesses casos a reflexão dinâmica ainda é aceitável porque o objetivo principal é debug, compatibilidade ou integração com runtime externo.

## Por que esta PR não altera gameplay

- nenhum valor de dano, HP, cooldown, XP, moeda, reward, defesa, knockback ou spawn foi alterado;
- nenhum signal foi reordenado;
- nenhuma cena principal foi alterada;
- nenhum resource `.tres` foi alterado;
- as mudanças só reduziram reflexão dinâmica em contratos que já existiam.

## Testes manuais

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar pelo play principal.
4. Confirmar `RunScene`.
5. Confirmar:
   - Gaia move;
   - câmera segue;
   - dash funciona;
   - ataque da Gaia funciona;
   - Goblin recebe dano;
   - dano híbrido/fraquezas continuam;
   - Goblin morre;
   - XP direta;
   - moeda dropa, magnetiza e coleta;
   - Goblin persegue e causa dano;
   - defesa/invulnerabilidade pós-hit;
   - level-up/upgrades;
   - HUD;
   - DebugOverlay/F3/F4;
   - vitória/derrota/result/save.
6. Rodar alguns minutos com vários Goblins e moedas.
7. Confirmar console sem erro novo.

## Riscos conhecidos

- `EnemyBase` ainda mantém chamadas dinâmicas para o visual controller; isso foi preservado para não acoplar demais a PR a Spine/visual.
- `RunHud` ainda consulta debug data por contrato dinâmico; custo existe, mas é secundário perto do hot path de combate e física.
- `CoinDrop` ainda usa contrato dinâmico para modifiers do player fora do loop crítico; isso pode ser formalizado depois junto com a arquitetura de pickups/upgrades.
