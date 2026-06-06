# Domínio — Drops e Moedas

`DropController` reage a `enemy_died` e cria `CoinDrop` conforme chance do inimigo. O drop físico utiliza `CoinDropDefinition` para magnetismo/coleta.

As moedas são **poolizadas** via `PoolManager`: o `DropController` instancia com `PoolManager.spawn_path(...)`, e o `CoinDrop` devolve ao pool com `PoolManager.despawn(self)` ao ser coletado/expirar, resetando o estado em `_on_pool_acquire()`.

## Regras

- matar não concede moeda automaticamente;
- a moeda precisa ser coletada;
- moeda abandonada é perdida;
- vitória aplica multiplicador do mapa apenas às moedas coletadas;
- derrota entrega moedas coletadas sem multiplicador.
