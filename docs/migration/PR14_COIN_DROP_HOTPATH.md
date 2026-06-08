# PR14 Coin Drop Hotpath

## Objetivo

Reduzir o custo residual do `CoinDrop.gd` no hot path depois da PR6, tornando a moeda mais orientada a eventos e limitando `_physics_process()` aos momentos em que a moeda realmente precisa se mover.

Esta PR nao muda:

- economia;
- chance/valor de drop;
- save;
- reward/result;
- HUD;
- feedback de moeda;
- fluxo de coleta.

## Estado anterior identificado

Antes desta PR, `CoinDrop.gd` ainda tinha dois custos residuais importantes:

1. `_physics_process()` ficava ligado enquanto a moeda estava ativa, mesmo parada no chao.
2. O script fazia `_refresh_area_overlap_state()` a cada frame, que por sua vez chamava `get_overlapping_bodies()` em `MagnetArea` e `CollectArea`.

Isso significava que moedas paradas, fora do alcance da Gaia, ainda faziam trabalho de overlap polling continuamente.

## Arquivos inspecionados

- `gameplay/drops/CoinDrop.gd`
- `gameplay/drops/CoinDrop.tscn`
- `definitions/CoinDropDefinition.gd`
- `gameplay/drops/DropController.gd`
- `autoloads/PoolManager.gd`
- `docs/migration/PR6_COIN_AREA2D_MAGNETISM.md`
- `docs/migration/PR13_FRAME_PROCESSING_AUDIT.md`

## Arquivos alterados

- `gameplay/drops/CoinDrop.gd`
- `gameplay/drops/CoinDrop.tscn`
- `.gitignore`

## Arquivos nao alterados

- `gameplay/drops/DropController.gd`
- `definitions/CoinDropDefinition.gd`
- `autoloads/PoolManager.gd`
- `RunScene`, `Main`, `PlayerController`, `RunController`, `EnemyBase`
- save/reward/result/HUD

## O que foi mudado

### 1. `CoinDrop` agora usa `Timer` para o idle inicial

Foi adicionado um node:

```text
CoinDrop
|- MagnetArea
|- CollectArea
`- IdleTimer
```

Em vez de contar `elapsed_seconds` em `_physics_process()`, a moeda agora:

- ativa um `IdleTimer` one-shot ao nascer/reusar;
- fica sem processamento de fisica enquanto esta apenas aguardando;
- so pode iniciar magnetismo quando esse timer conclui.

### 2. `_physics_process()` agora roda so quando ha trabalho real

O processamento de fisica fica ligado apenas quando:

- a moeda esta magnetizada e precisa acelerar em direcao ao player; ou
- a moeda acabou de perder o alvo e ainda precisa desacelerar ate parar.

O processamento de fisica fica desligado quando:

- a moeda acabou de nascer e esta no idle inicial;
- a moeda esta parada fora do `MagnetArea`;
- a moeda foi coletada;
- a run terminou;
- a moeda voltou ao pool.

### 3. Polling por frame foi removido

`get_overlapping_bodies()` nao e mais usado por frame.

Agora ele existe apenas em sincronizacoes pontuais:

- ao ativar/reusar a moeda;
- ao refrescar raios apos level-up concluido.

Ou seja:

- nao ha mais `get_overlapping_bodies()` no hot path por frame;
- o overlap continuo ficou a cargo dos sinais nativos `body_entered/body_exited`.

### 4. `MagnetArea` e `CollectArea` ficaram mais event-driven

Fluxo atual:

1. moeda nasce;
2. `IdleTimer` inicia;
3. `MagnetArea.body_entered` marca que o player esta no raio;
4. quando o idle termina, a moeda liga fisica apenas se houver player no raio;
5. enquanto magnetizada, a moeda move e acelera;
6. se o player sair do raio, a moeda desacelera e depois dorme;
7. `CollectArea.body_entered` coleta imediatamente.

## Como o hot path ficou melhor

### Antes

- moedas paradas ainda rodavam `_physics_process()`;
- moedas paradas ainda consultavam overlaps a cada frame.

### Depois

- moedas paradas nao processam fisica;
- moedas fora do alcance nao consultam overlaps por frame;
- moedas so processam movimento quando realmente estao em movimento/magnetismo;
- areas continuam nativas e dirigidas por sinais.

## Compatibilidade com upgrades de magnetismo/coleta

Para nao perder compatibilidade com upgrades que alteram raios durante a run, a moeda agora tambem reage a:

- `GameEvents.run_level_up_completed`

Nessa hora, ela:

- recalcula `magnet_radius` e `collect_radius` efetivos;
- faz uma sincronizacao pontual de overlap;
- reavalia se deve acordar ou permanecer dormindo.

Isso evita voltar ao polling por frame e ainda cobre o caso mais importante de upgrades durante a run.

## Pooling e lifecycle

O pooling continua seguro:

- `_on_pool_acquire()` deixa a moeda inerte ate `setup()`;
- `_on_pool_release()` desliga areas, shapes, timer e fisica;
- `player_node`, `velocity`, flags de overlap, flags de coleta e cache de raios sao limpos no reuso;
- `IdleTimer` e parado no acquire/release/coleta/fim da run.

## `.godot/` no `.gitignore`

Foi adicionada a regra:

- `.godot/`

Motivo:

- havia arquivo nao rastreado do editor (`.godot/editor/filesystem_update4`);
- esse tipo de arquivo nao deve entrar no versionamento.

## O que nao mudou

- `default_value`
- `magnet_radius`
- `collect_radius`
- `initial_idle_seconds`
- `magnet_acceleration`
- `max_magnet_speed`
- `coin_drop_chance`
- `coin_drop_value`
- `GameEvents.run_coin_collected`
- resultado final da run
- save
- reward resolver

## Riscos conhecidos

- upgrades de magnetismo/coleta agora refrescam raios no fim de level-up, mas nao existe ainda um canal dedicado so para mudanca de modificadores de coleta; se no futuro houver outro fluxo que altere esses multiplicadores sem passar por level-up, sera bom adicionar um sinal especifico.
- `get_overlapping_bodies()` ainda existe em sincronizacao pontual de spawn/reuso/upgrade. Isso foi mantido de proposito para cobrir casos de overlap ja existente sem voltar ao polling por frame.

## Testes manuais necessarios

1. Abrir o projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar o jogo pelo play principal.
4. Confirmar `RunScene`.
5. Matar Goblins ate dropar moeda.
6. Confirmar que a moeda nasce no chao.
7. Confirmar que a moeda fica parada por `initial_idle_seconds`.
8. Aproximar Gaia do `MagnetArea`.
9. Confirmar que a moeda comeca a magnetizar.
10. Sair/entrar do raio e confirmar comportamento consistente.
11. Confirmar que a moeda acelera corretamente.
12. Confirmar que a moeda respeita `max_magnet_speed`.
13. Confirmar que a moeda coleta no `CollectArea`.
14. Confirmar HUD de moedas.
15. Confirmar feedback de moeda, se habilitado.
16. Confirmar que moeda nao coletada nao entra no resultado.
17. Confirmar vitoria/derrota/result/save.
18. Confirmar upgrades de magnetismo/coleta, se disponiveis.
19. Gerar varias moedas para validar reuso do pool.
20. Confirmar ataque, dash, Goblin, XP, level-up e upgrades.
21. Confirmar console sem erro novo.

## Resultado

`CoinDrop` continua com o mesmo comportamento percebido pelo jogador, mas deixou de fazer polling de overlaps por frame e deixou de rodar fisica enquanto esta apenas existindo parada no mapa. O hot path agora fica concentrado no momento em que a moeda realmente precisa se mover.
