# Lifecycle - Coin Drop

```text
EnemyBase morre
-> GameEvents.enemy_died
-> DropController avalia chance
-> PoolManager.spawn da CoinDrop em DropRoot
-> _on_pool_acquire reseta estado
-> idle inicial
-> MagnetArea/CollectArea ativadas
-> signals nativos detectam a Gaia
-> moeda magnetiza quando necessario
-> run_coin_collected + run_coins_changed
-> RunState soma moeda coletada
-> PoolManager.despawn(self)
```

## Estado atual

- `CoinDrop` usa `Area2D` e `CollisionShape2D` para magnetismo e coleta.
- O fluxo principal e orientado a signals.
- `_physics_process()` so fica ligado quando a moeda realmente precisa se mover.
- A moeda e poolizada: nasce via `PoolManager.spawn` e volta via `PoolManager.despawn(self)`.

## Regras importantes

- Matar inimigo nao concede moeda automaticamente.
- A moeda so conta quando e coletada.
- Moeda nao coletada nao entra no resultado final.
- A coleta para quando a run esta encerrando ou finalizada.
