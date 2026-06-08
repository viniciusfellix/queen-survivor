# PR22 - Spawn Timeline V2

## Objetivo

Evoluir o sistema de waves/spawn timeline para suportar:

- imprevisibilidade de inicio/fim;
- multiplas waves simultaneas;
- multiplas regras/inimigos por wave;
- probabilidade por regra;
- janela interna por regra;
- boss/elite por configuracao;
- limite total de spawns por regra.

Tudo isso sem alterar:

- combate;
- dano;
- moeda;
- XP/level-up;
- save/reward/result.

## Limitacao do sistema antigo

Antes desta PR:

- a timeline retornava apenas **uma** entry ativa por vez;
- cada entry tinha **um unico inimigo** embutido;
- nao existia regra individual por inimigo;
- nao existia probabilidade por inimigo/regra;
- nao existia range de tempo de inicio/fim;
- nao existia `max_total_spawns` por regra;
- elite/boss exigiriam gambiarra em `EnemySpawner` ou duplicacao de entries.

Na pratica, o sistema era suficiente para o Goblin basico, mas rigido demais para design de survivor-like com picos, sobreposicoes e inimigos raros.

## Novo conceito de timeline

`SpawnTimelineDefinition` agora:

- continua agrupando `entries`;
- ganhou `get_active_entries(elapsed_seconds)`;
- manteve `get_active_entry(elapsed_seconds)` como compatibilidade legacy.

Isso permite que a camada runtime escolha:

- uma wave exclusiva;
- varias waves concorrentes;
- ou combinacoes das duas.

## Novo conceito de wave / entry

`SpawnTimelineEntryDefinition` agora suporta:

- `id`
- `wave_name`
- `start_time_seconds` / `end_time_seconds` legacy
- `start_time_min_seconds`
- `start_time_max_seconds`
- `end_time_min_seconds`
- `end_time_max_seconds`
- `allow_concurrent`
- `spawn_rules: Array[SpawnRuleDefinition]`

Campos legacy foram mantidos:

- `enemy_scene_path`
- `enemy_definition`
- `spawn_interval_seconds`
- `max_alive_enemies`
- `spawn_min_distance`
- `spawn_max_distance`
- `spawn_on_activate`

Quando `spawn_rules` esta vazio, a entry cria uma **legacy rule runtime** automaticamente para manter compatibilidade com resources antigos.

## Novo conceito de spawn rule

Foi criado:

- `res://definitions/SpawnRuleDefinition.gd`

Campos principais:

- `id`
- `enabled`
- `enemy_scene_path`
- `enemy_definition`
- `spawn_probability_percent`
- `spawn_interval_min_seconds`
- `spawn_interval_max_seconds`
- `max_total_spawns`
- `max_alive`
- `active_from_seconds`
- `active_until_seconds`
- `spawn_on_activate`
- `tags`

Isso separa:

- o **quando a wave existe**;
- do **como cada inimigo/regra se comporta dentro dela**.

## Como funciona a randomizacao de start/end

O sorteio acontece em `EnemySpawner`, uma vez por run/setup.

Para cada wave:

1. o spawner le os ranges efetivos da entry;
2. sorteia `runtime_start_time_seconds`;
3. sorteia `runtime_end_time_seconds`, garantindo que o fim nunca fique antes do inicio;
4. guarda esses valores em runtime state.

Importante:

- o resource `.tres` nao e mutado;
- o sorteio nao acontece a cada frame;
- o mesmo runtime de uma wave permanece estavel durante toda a run.

## Como funciona multipla wave simultanea

O spawner agora separa waves ativas em dois grupos:

- `allow_concurrent = true`
- `allow_concurrent = false`

Regra aplicada:

- todas as waves concorrentes ativas entram no processamento;
- entre as waves exclusivas ativas, apenas a que iniciou mais tarde entra;
- as duas familias podem coexistir.

Isso permite:

- wave normal exclusiva;
- uma wave extra de elite/boss concorrente;
- ou varias waves concorrentes, se o designer quiser.

## Como funcionam multiplas rules/inimigos por wave

Cada entry processa `spawn_rules` independentes.

Cada regra tem seu proprio runtime state:

- `activated_once`
- `next_spawn_time_seconds`
- `total_spawned`
- `alive_count`

Assim, uma mesma wave pode ter:

- Goblin comum 100%;
- elite 10%;
- boss 5% com `max_total_spawns = 1`;
- janelas internas diferentes.

## Como funciona probabilidade por rule

A cada tentativa da regra:

- `spawn_probability_percent >= 100` -> sempre tenta spawnar;
- `<= 0` -> nunca spawna;
- valor intermediario -> rola percentual por tentativa.

Importante:

- a probabilidade e avaliada por tentativa;
- a regra continua respeitando intervalo min/max entre tentativas;
- falha por probabilidade nao trava a regra, apenas consome aquela tentativa.

## Como funciona max_total_spawns

`max_total_spawns` e controlado por runtime state da regra.

Comportamento:

- `<= 0` -> ilimitado;
- `> 0` -> apos atingir o total, a regra para de spawnar.

Isso cobre bem casos como:

- boss com `max_total_spawns = 1`;
- elite rara com `max_total_spawns = 3`.

## Max alive por rule

Foi **implementado** nesta PR.

Como:

- cada inimigo spawnado por rule conecta `tree_exited`;
- quando sai da arvore, decrementa `alive_count` daquela rule;
- o spawner consulta `spawn_rule.max_alive` antes de spawnar de novo.

Observacao:

- o cap global do spawner continua existindo e continua segurando excesso geral;
- o cap por rule e complementar, nao substitui o cap global.

## EnemySpawner V2

`EnemySpawner.gd` agora:

- inicializa runtime state das waves/rules uma vez por run;
- processa `get_runtime_active_entries`;
- processa multiplas rules por entry;
- respeita:
  - probabilidade;
  - intervalo min/max;
  - `max_total_spawns`;
  - `max_alive` por rule;
  - janela `active_from_seconds` / `active_until_seconds`;
  - cap global `max_alive_enemies`.

O spawn continua usando:

- `PoolManager.spawn_path()`
- `EnemyBase.setup(enemy_definition, player_node)`

Sem alterar `EnemyBase`.

## Timeline atual do mapa

A timeline oficial do mapa `map_test_arena_10min` foi migrada para o novo formato com:

- rules explicitas por wave;
- uma rule de Goblin por wave;
- comportamento conservador para nao quebrar a run atual;
- ranges pequenos de inicio/fim para introduzir imprevisibilidade real.

Ranges atuais:

- `wave_00_intro`: fim entre `112s` e `128s`
- `wave_01_build_up`: inicio `112s-128s`, fim `290s-310s`
- `wave_02_pressure`: inicio `290s-310s`, fim `470s-490s`
- `wave_03_final_push`: inicio `470s-490s`, fim `595s-600s`

## Boss e elite

Esta PR prepara o sistema para boss/elite por configuracao, mas **nao inventa inimigo novo** sem asset/scene propria.

Estrutura pronta:

- `tags = ["elite"]` ou `["boss"]`
- `spawn_probability_percent` baixo
- `max_total_spawns = 1`
- `active_from_seconds` / `active_until_seconds`
- `allow_concurrent = true` na wave correspondente

Conteudo final de elite/boss continua pendente de art/scene/definition dedicadas.

## Resources criados / alterados

### Criado

- `definitions/SpawnRuleDefinition.gd`
- `data/spawn_timelines/test_arena_10min/rule_wave_00_intro_goblin.tres`
- `data/spawn_timelines/test_arena_10min/rule_wave_01_build_up_goblin.tres`
- `data/spawn_timelines/test_arena_10min/rule_wave_02_pressure_goblin.tres`
- `data/spawn_timelines/test_arena_10min/rule_wave_03_final_push_goblin.tres`

### Alterado

- `definitions/SpawnTimelineDefinition.gd`
- `definitions/SpawnTimelineEntryDefinition.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `data/spawn_timelines/test_arena_10min/wave_00_intro.tres`
- `data/spawn_timelines/test_arena_10min/wave_01_build_up.tres`
- `data/spawn_timelines/test_arena_10min/wave_02_pressure.tres`
- `data/spawn_timelines/test_arena_10min/wave_03_final_push.tres`
- `data/spawn_timelines/test_arena_10min/spawn_timeline_test_arena_10min.tres`

## O que foi removido/limpo do sistema antigo

Foi removida a duplicacao inline de `wave_00_intro` dentro de:

- `spawn_timeline_test_arena_10min.tres`

Agora a timeline usa apenas resources externos para todas as waves, alinhando o conjunto.

Nao removi os campos legacy das entries porque eles ainda servem como fallback seguro e reduzem risco de regressao.

## O que ficou para futuro

- criar enemy real de elite;
- criar enemy real de boss;
- presets prontos de waves concorrentes usando conteudo final;
- UI/debug especifica para inspecionar runtime start/end sorteados;
- se necessario, prewarm por scene de rule em vez de usar apenas `enemy_scene_path` fallback do spawner.

## Testes manuais

1. Abrir projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar pelo Play principal.
4. Confirmar `RunScene`.
5. Confirmar que Goblins spawnam.
6. Confirmar que Goblins perseguem, causam dano, recebem dano e morrem.
7. Confirmar XP direta.
8. Confirmar moedas.
9. Confirmar level-up.
10. Confirmar vitoria/derrota/result/save.
11. Rodar mais de uma vez e validar que os tempos reais de troca entre waves nao sao identicos.
12. Validar uma rule com 100% de chance.
13. Ajustar uma rule para chance baixa e validar comportamento intermitente.
14. Ajustar `max_total_spawns = 1` e validar que nao passa de 1.
15. Ajustar `allow_concurrent = true` em duas waves e validar coexistencia.
16. Confirmar que o cap global continua segurando excesso.
17. Confirmar console sem erro novo.
