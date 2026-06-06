# Domínio — Debug e Auditoria

Ferramentas atuais:

- `DeveloperAuditLogger` e canais;
- `DebugOverlay`, inclusive linhas opcionais Gaia-inimigos;
- `PrototypeToolsPanel` (`F3` e `F4`);
- `RuntimeTreeSnapshot` com compactação Spine;
- exportador de árvore de cenas para auditoria.

Canais detalhados (`COMBAT`, `ANIMATION`, `SPAWN`, `UI`) devem ser ativados apenas durante investigações e desligados após validação.

## Redraw de debug guardado por flag

O `queue_redraw()` dos visuais de debug só é reagendado quando a flag correspondente está ligada — `EnemyBase`/`PlayerController`/`CoinDrop` usam o helper `_queue_debug_redraw()`, que só reagenda o `_draw` se `draw_debug_visual` / `draw_debug_aim` / `draw_debug_hitbox` estiver ativa (evita sujar o canvas por frame com debug desligado). `DirectionalAttackHitbox` só chama `queue_redraw()` uma vez no setup.
