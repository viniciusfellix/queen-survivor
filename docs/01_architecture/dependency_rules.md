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

## Prevenção de redundância

Antes de criar métodos repetidos em duas entidades, avalie uma base comum sem ocultar responsabilidade. Bases já consolidadas:

- `SpineAnimationAdapterBase`;
- `SpineVisualControllerBase`;
- `CombatShapeDefinition`;
- `HurtboxComponent`.

## Critério de conclusão

Uma funcionalidade só encerra após auditoria estrutural, comentários inline, regressão e documentação.
