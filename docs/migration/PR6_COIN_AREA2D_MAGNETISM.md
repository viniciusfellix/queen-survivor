# PR6 Coin Area2D Magnetism

## Objetivo

Refatorar a moeda física da run para usar detecção idiomática de magnetismo e coleta com `Area2D` + `CollisionShape2D`, preservando a economia atual, o contrato com `DropController` e o comportamento já esperado em runtime.

## Comportamento anterior identificado

Antes desta PR, `CoinDrop`:

- usava `Node2D` como root;
- calculava `distance_to(player)` a cada `_physics_process()` para decidir:
  - quando iniciar magnetismo;
  - quando coletar;
- continuava usando `CoinDropDefinition` para raios, aceleração, velocidade máxima e debug;
- emitia `GameEvents.run_coin_collected` corretamente ao coletar.

O comportamento geral estava funcional, mas a detecção de proximidade era manual demais para um fluxo que o motor já resolve bem com `Area2D`.

## Nova abordagem com Area2D

`CoinDrop` continua com root `Node2D`, mas agora possui duas áreas nativas:

- `MagnetArea: Area2D`
- `CollectArea: Area2D`

Cada uma possui seu próprio `CollisionShape2D` com `CircleShape2D`.

Fluxo novo:

1. a moeda nasce no `DropRoot` como antes;
2. `setup(coin_definition, value, player_node)` continua sendo usado como antes;
3. `CoinDropDefinition` continua alimentando:
   - `default_value`;
   - `magnet_radius`;
   - `collect_radius`;
   - `initial_idle_seconds`;
   - `magnet_acceleration`;
   - `max_magnet_speed`;
   - `debug_radius`;
   - cores de debug;
4. `MagnetArea` detecta o body do player via `body_entered/body_exited`;
5. depois de `initial_idle_seconds`, a moeda só passa a se mover se o player estiver dentro de `MagnetArea`;
6. `CollectArea` detecta o player via `body_entered` e dispara coleta;
7. a moeda continua emitindo `GameEvents.run_coin_collected` e sendo removida por `PoolManager.despawn(self)`.

## Nodes adicionados na CoinDrop

Estrutura final:

```text
CoinDrop
├── MagnetArea
│   └── CollisionShape2D
└── CollectArea
    └── CollisionShape2D
```

## Layers e masks usadas

Foram usadas/preservadas as seguintes regras:

- `PlayerGaia` continua como `CharacterBody2D` em `collision_layer = 2`;
- `MagnetArea` usa:
  - `collision_layer = 0`
  - `collision_mask = 2`
- `CollectArea` usa:
  - `collision_layer = 0`
  - `collision_mask = 2`

Escolha feita:

- a moeda detecta diretamente o body do player;
- não foi necessário alterar `PlayerHurtbox`, `PlayerController` ou layers de combate;
- combate e coleta continuam desacoplados.

## Arquivos alterados

- `gameplay/drops/CoinDrop.tscn`
- `gameplay/drops/CoinDrop.gd`

## Arquivos não alterados

- `gameplay/drops/DropController.gd`
- `definitions/CoinDropDefinition.gd`
- `data/drops/coin_default.tres`
- `scenes/Main.gd`
- `scenes/run/RunScene.tscn`
- `gameplay/test/TestGaiaScene.tscn`
- sistemas de save, reward, result, XP, upgrades, combate, dash e UI

## Por que a economia não mudou

Esta PR não altera:

- chance de drop;
- valor de moeda por inimigo;
- valor default do resource;
- critérios de vitória/derrota;
- resultado;
- save;
- HUD;
- evento global `run_coin_collected`.

Só mudou a forma de detectar proximidade do player para magnetismo e coleta.

## Compatibilidade com modifiers do player

Os raios de `MagnetArea` e `CollectArea` continuam respeitando os modifiers do player:

- `coin_magnet_radius_multiplier`
- `coin_collect_radius_multiplier`

Os `CircleShape2D` são atualizados em runtime a partir desses multiplicadores, sem voltar ao cálculo manual de distância para disparar magnetismo/coleta.

## Testes manuais necessários

1. Abrir o projeto no Godot.
2. Confirmar que não há missing files.
3. Rodar o jogo pelo botão principal/play.
4. Confirmar que a cena carregada é `RunScene`.
5. Matar Goblins até dropar moeda.
6. Confirmar que a moeda nasce no chão.
7. Confirmar que a moeda fica parada inicialmente.
8. Aproximar a Gaia até o raio de magnetismo.
9. Confirmar que a moeda começa a ser atraída.
10. Afastar e aproximar, se possível, para validar comportamento.
11. Confirmar que a moeda respeita velocidade máxima.
12. Confirmar que a moeda é coletada no raio de coleta.
13. Confirmar que HUD de moedas aumenta.
14. Confirmar que `GameEvents.run_coin_collected` continua funcionando.
15. Confirmar que `RunFeedbackLayer` ainda mostra feedback de moeda, se habilitado.
16. Confirmar que vitória usa moedas coletadas.
17. Confirmar que derrota usa moedas coletadas.
18. Confirmar que moeda não coletada não entra no resultado.
19. Confirmar que não há erro novo no console.
20. Confirmar que dash, ataque, Goblin, XP e level-up continuam funcionando.

## Riscos conhecidos

- como a moeda agora depende de overlap de `Area2D`, upgrades de raio em runtime precisam ser validados manualmente no jogo real para confirmar que a atualização dos shapes cobre todos os casos esperados;
- a detecção foi configurada contra o body do player em layer 2; se no futuro a coleta migrar para uma área dedicada do player, essa decisão precisará ser revisitada;
- a cena continua com placeholder técnico desenhado por `_draw()`, então qualquer futura troca para visual artístico deve preservar as duas áreas e seus contratos.

## Próximos passos esperados

1. validar manualmente a moeda no runtime oficial;
2. decidir em PR futura se outros pickups físicos devem seguir o mesmo padrão;
3. manter `DropController` enxuto, sem transformar esta PR em abstração genérica de todos os drops.
