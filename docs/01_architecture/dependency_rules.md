# Arquitetura — Regras de Dependência

## Direção preferencial

```text
Definitions / Resources
→ Controllers de Gameplay
→ Estado e Eventos
→ UI e Visual
```

## Regras obrigatórias

1. Resources armazenam configuração; controllers executam comportamento runtime.
2. `DamageResolver`, `RewardResolver` e `LevelUpOptionService` concentram regras determinísticas reutilizáveis.
3. UI exibe estado/eventos e não calcula dano ou recompensa.
4. Spine representa estado e não decide gameplay.
5. `BodyCollision`, `Hitbox` e `Hurtbox` são responsabilidades distintas.
6. Game design deve conseguir editar dano, shapes, drops e recompensas por `.tres` quando a regra já existe.
7. Logs operacionais passam pelo `DeveloperAuditLogger`.
8. Criação/destruição de nós de alta rotatividade (inimigos, moedas, hitbox de ataque, texto flutuante) passa pelo `PoolManager` (`spawn`/`despawn`), não por `instantiate()`/`queue_free()` direto. Fallback `queue_free` só quando o nó não é poolado.
9. A pausa de gameplay usa `get_tree().paused` (definido pelo `RunController` no level-up e fim de run) + `process_mode = ALWAYS` nos nós de UI — não há mais checagem por frame (`is_gameplay_blocked` foi removido).
10. Caminhos de dano usam `class_name` + cast tipado (`as EnemyBase` / `as PlayerController`) e chamada direta, em vez de `has_method`+`call`. Exceção: `HurtboxComponent` mantém `has_method` de propósito, por ser componente genérico que não acopla a tipos do jogo.

## Prevenção de redundância

Antes de criar métodos repetidos em duas entidades, avalie uma base comum sem ocultar responsabilidade. Bases já consolidadas:

- `SpineAnimationAdapterBase`;
- `SpineVisualControllerBase`;
- `CombatShapeDefinition`;
- `HurtboxComponent`.

## Critério de conclusão

Uma funcionalidade só encerra após auditoria estrutural, comentários inline, regressão e documentação.
