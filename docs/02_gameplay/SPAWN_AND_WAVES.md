# Spawn And Waves

## Spawn Timeline V2

O sistema atual suporta:

- multiplas waves ativas ao mesmo tempo
- `start/end` com range
- `allow_concurrent`
- multiplas `spawn_rules` por wave
- probabilidade por rule
- `max_total_spawns`
- `max_alive` por rule quando configurado
- tags tecnicas para `normal`, `elite`, `boss`

## Resources centrais

- `SpawnTimelineDefinition`
- `SpawnTimelineEntryDefinition`
- `SpawnRuleDefinition`

## Comportamento atual

- o `EnemySpawner` resolve ranges de tempo por run
- cada rule controla sua propria janela interna
- o spawner continua respeitando limite global de inimigos vivos
- o Goblin atual segue funcionando como baseline oficial

## Elite e boss

O sistema ja permite configurar elite/boss por resource, mesmo sem conteudo final dedicado para todos os casos.

## Follow-up futuro

- prewarm por rule com conteudo mais variado
- conteudo real de elite/boss
