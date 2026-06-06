# ADR 0011 — Object Pooling para Entidades

## Status

Aceita.

## Problema

A arena infinita precisa sustentar milhares de entidades simultâneas (inimigos, moedas, hitboxes e visuais de ataque, textos flutuantes). Instanciar (`instantiate()`) e destruir (`queue_free()`) cada entidade a todo momento gera custo contínuo de alocação, parse de cena e coleta, além de picos de GC que prejudicam o desempenho em hordas.

## Decisão

Introduzir o autoload `PoolManager` (`autoloads/PoolManager.gd`) como pool genérico de cenas:

- mantém uma **fila por cena** de instâncias inativas;
- instâncias inativas ficam **fora da árvore** (não processam nem colidem);
- `get_scene` cacheia o `load` de cada `PackedScene`.

API oficial:

- `spawn` / `spawn_path(..., at_global_position)` — retira da fila (ou instancia se vazia) e ativa;
- `despawn` — desativa e devolve à fila;
- `prewarm` — pré-popula a fila.

A posição global é aplicada **antes** do `add_child`, evitando frame inicial em posição errada. As entidades poolizadas implementam os hooks `_on_pool_acquire` / `_on_pool_release` para reset/limpeza de estado.

## Fluxos oficiais

```text
spawn → _on_pool_acquire → entidade ativa na árvore
morte/coleta/expiração → PoolManager.despawn(self) → _on_pool_release → fila
```

Fallback: quando não houver pool aplicável, usa-se `queue_free()`.

## Entidades poolizadas

- inimigos (`EnemySpawner.prewarm_pool_count`, default `24`);
- moedas;
- hitbox e visual de ataque;
- texto flutuante.

## Benefícios

- suporta milhares de entidades sem custo de criar/destruir por frame;
- elimina picos de GC em hordas;
- reset de estado centralizado nos hooks;
- pré-aquecimento configurável por designer no spawner.

## Conceitos removidos

Inimigos, moedas, hitbox/visual de ataque e texto flutuante não devem mais ser criados/destruídos por `instantiate()` + `queue_free()` direto no caminho quente; usar `PoolManager.spawn` / `PoolManager.despawn`.
