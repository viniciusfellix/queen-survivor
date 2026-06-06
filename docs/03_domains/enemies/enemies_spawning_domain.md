### Pooling de inimigos

`EnemySpawner` reaproveita inimigos via `PoolManager` (autoload): no spawn usa `PoolManager.spawn_path(...)` (com a posição aplicada **antes** do `add_child`, para o inimigo não nascer em `(0,0)`), e na morte o `EnemyBase` chama `PoolManager.despawn(self)`. O export `prewarm_pool_count` (default `24`) pré-aquece a fila no início.

A contagem de inimigos vivos é **O(1)**: `EnemySpawner._get_alive_enemy_count()` lê o contador incremental `_alive_enemy_count` (++ no spawn, -- via signal `enemy_died`), não mais `get_nodes_in_group("enemy")`.

### Esbarrão físico entre inimigos

`EnemyDefinition` define parâmetros de esbarrão:

- `body_bump_enabled`;
- `body_bump_power`;
- `body_bump_velocity_per_power`;
- `body_bump_max_velocity`;
- `body_bump_decay_per_second`;
- `body_bump_lateral_influence`.

Esses parâmetros permitem que inimigos maiores empurrem inimigos menores e que inimigos equivalentes se afastem de forma equilibrada.

O sistema não substitui IA, não cria formação e não causa dano.
