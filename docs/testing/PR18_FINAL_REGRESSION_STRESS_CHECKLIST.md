# PR18 - Final Regression and Stress Checklist

## Objetivo

Checklist final de regressao e stress test para validar o estado atual do projeto depois das PRs de migracao arquitetural, pooling, hot path cleanup, debug/dev-only cleanup e consolidacao documental.

Este documento e de QA. Ele nao assume que tudo esta aprovado; cada item deve ser marcado manualmente durante a validacao.

## Como classificar cada item

Use uma destas classificacoes:

- `PASS`
- `FAIL`
- `BLOCKER`
- `NEEDS FOLLOW-UP`
- `NOT TESTED`

Campos recomendados por item:

- `Status`
- `Observacao`
- `Evidencia`
- `Arquivo/sistema afetado`
- `Prioridade`

Prioridades sugeridas:

- `P0` bloqueia validacao externa/manual
- `P1` bug importante, mas com workaround
- `P2` problema secundario
- `P3` ajuste futuro/observacao

## Template rapido de registro

```text
Status:
Observacao:
Evidencia:
Arquivo/sistema afetado:
Prioridade:
```

## A. Boot e cena oficial

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Abrir projeto no Godot sem missing files | PASS |  |  | boot / projeto | P0 |
| Rodar pelo Play principal | NOT TESTED |  |  | Main / boot | P0 |
| Confirmar que `RunScene` e carregada | PASS |  |  | `scenes/Main.gd`, `scenes/run/RunScene.tscn` | P0 |
| Confirmar que `Main.gd` aponta para `res://scenes/run/RunScene.tscn` | PASS |  |  | `scenes/Main.gd` | P0 |
| Confirmar que `TestGaiaScene` existe apenas como legado/referencia | PASS |  |  | `gameplay/test/TestGaiaScene.tscn` | P2 |

## B. Gaia e camera

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Gaia nasce no spawn correto | PASS |  |  | RunScene / Player spawn | P0 |
| Camera segue Gaia | PASS |  |  | `FollowCamera.gd` | P0 |
| Movimento WASD funciona | PASS |  |  | `PlayerController.gd` / Input Map | P0 |
| Movimento por setas funciona | PASS |  |  | `PlayerController.gd` / Input Map | P1 |
| Facing visual segue movimento horizontal | PASS |  |  | visual Gaia | P1 |
| Mira independente por mouse continua | PASS |  |  | input / player | P0 |
| Mira independente por analogico continua | NOT TESTED |  |  | input / player | P2 |
| Ultima direcao valida de mira continua correta | PASS |  |  | runtime state da Gaia | P1 |

## C. Dash

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Dash executa | PASS |  |  | `PlayerController.gd` | P0 |
| Cooldown do dash funciona | PASS |  |  | dash runtime | P1 |
| Controle lateral leve durante dash funciona | PASS |  |  | dash / movimento | P2 |
| Invulnerabilidade configuravel durante dash funciona | PASS |  |  | player damage flow | P1 |
| Dash nao causa dano via BodyCollision | PASS |  |  | body collision / dash | P0 |
| `PlayerDashImpactArea` aplica impacto/knockback corretamente, se configurada | PASS |  |  | dash impact area | P1 |
| Arma durante dash respeita configuracao atual | PASS |  |  | player + weapon + dash contract | P1 |

## D. Ataque da Gaia

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Ataque sai na direcao da mira | PASS |  |  | `GaiaInitialWeaponController.gd` | P0 |
| Visual do ataque aparece | PASS |  |  | `GaiaAttackVisualController.gd` | P1 |
| Visual do ataque desaparece corretamente | PASS |  |  | pooling visual | P1 |
| `DirectionalAttackHitbox` acerta Goblins | PASS |  |  | `DirectionalAttackHitbox.gd` | P0 |
| Nao ha hit duplicado indevido por mesma instancia | PASS |  |  | attack hitbox pooling/reuse | P0 |
| Dano fisico + magico continua | PASS |  |  | damage payload / resolver | P0 |
| Fraqueza fisica/magica continua | PASS |  |  | enemy definition / resolver | P1 |
| Knockback da arma continua, se configurado | PASS |  |  | attack hitbox / enemy knockback | P2 |
| Cooldown da arma funciona | PASS |  |  | weapon controller / HUD | P1 |

## E. Inimigos

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Goblins spawnam | PASS |  |  | `EnemySpawner.gd` | P0 |
| Goblins perseguem Gaia | PASS |  |  | `EnemyBase.gd` | P0 |
| Body bump entre inimigos funciona | PASS |  |  | enemy movement | P2 |
| Player body slide funciona | PASS |  |  | enemy/player body slide | P2 |
| Goblins atacam via `EnemyAttackHitbox` | PASS |  |  | `EnemyAttackHitbox.gd` | P0 |
| Goblins nao causam dano via `BodyCollision` | PASS |  |  | collision contract | P0 |
| Goblins recebem dano | PASS |  |  | hurtbox + enemy receiver | P0 |
| Goblins morrem | PASS |  |  | enemy lifecycle | P0 |
| `enemy_died` emite uma vez por morte | PASS |  |  | events / enemy death | P0 |
| Goblin morto nao continua causando dano | PASS |  |  | attack hitbox shutdown | P0 |
| Goblin reutilizado pelo pool volta vivo sem death/flash antigo | PASS |  |  | enemy pooled reuse | P1 |

## F. XP, level-up e upgrades

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| XP entra direto | PASS |  |  | `RunController.gd` / `RunState.gd` | P0 |
| XP nao vira drop fisico | PASS |  |  | death reward flow | P0 |
| Barra de XP atualiza | PASS |  |  | HUD | P1 |
| Level-up abre | PASS |  |  | `LevelUpPanel.gd` | P0 |
| 3 opcoes aparecem | PASS |  |  | options service / panel | P1 |
| Icones e badges aparecem | PASS |  |  | level-up UI | P2 |
| Escolha aplica upgrade | PASS |  |  | player/weapon/run upgrade flow | P0 |
| Painel fecha | PASS |  |  | level-up UI | P1 |
| Run continua depois da escolha | PASS |  |  | pause/unpause flow | P0 |
| Upgrade de dano fisico testado | PASS |  |  | upgrade flow | P1 |
| Upgrade de dano magico testado | PASS |  |  | upgrade flow | P1 |
| Upgrade de cooldown testado | PASS |  |  | upgrade flow | P1 |
| Upgrade de area/lifetime testado | PASS |  |  | weapon upgrade flow | P2 |
| Upgrade de velocidade testado | PASS |  |  | player upgrade flow | P2 |
| Upgrade de HP testado | PASS |  |  | player upgrade flow | P2 |
| Upgrade de defesa testado | PASS |  |  | player upgrade flow | P2 |
| Upgrade de cura testado | PASS|  |  | player upgrade flow | P2 |
| Upgrade de magnetismo/coleta testado | PASS |  |  | drop modifiers | P1 |
| Upgrade de dash testado, se houver | PASS |  |  | dash resource flow | P3 |

## G. Moedas

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Moeda dropa no chao | PASS |  |  | `DropController.gd` / `CoinDrop.gd` | P0 |
| Moeda fica idle pelo tempo configurado | PASS |  |  | `CoinDrop.gd` / definition | P1 |
| `MagnetArea` detecta Gaia | PASS |  |  | `CoinDrop.tscn` | P1 |
| `CollectArea` coleta Gaia | PASS |  |  | `CoinDrop.tscn` | P0 |
| `_physics_process` da moeda nao roda desnecessariamente quando idle/fora do raio | PASS |  |  | coin hot path | P1 |
| Moeda magnetiza corretamente | PASS |  |  | coin movement | P0 |
| Moeda respeita velocidade maxima | PASS |  |  | coin movement | P2 |
| Moeda coletada soma no HUD | PASS |  |  | run coins / HUD | P0 |
| Moeda nao coletada nao entra no resultado | PASS |  |  | result / reward | P0 |
| Reuso de moeda pooled nao traz estado sujo | PASS |  |  | coin pooling | P1 |

## H. Resultado e save

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Vitoria funciona | PASS |  |  | run finish | P0 |
| Derrota funciona | PASS |  |  | run finish | P0 |
| `ResultPanel` abre | PASS |  |  | result UI | P0 |
| Dinheiro final de vitoria aplica multiplicador + bonus | PASS |  |  | reward resolver | P1 |
| Derrota usa apenas moedas coletadas | PASS |  |  | result / reward | P0 |
| XP da run persiste | PASS |  |  | save / result | P1 |
| `SaveManager` salva resultado | PASS |  |  | save flow | P0 |
| Status de persistencia aparece | PASS |  |  | result / save UI | P2 |
| Restart funciona | PASS |  |  | result / boot flow | P1 |

## I. UI e localizacao

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| HUD mostra HP | PASS |  |  | RunHud | P1 |
| HUD mostra XP | PASS |  |  | RunHud | P1 |
| HUD mostra cooldown | PASS |  |  | RunHud | P1 |
| HUD mostra timer | PASS |  |  | RunHud | P1 |
| HUD mostra moedas | PASS |  |  | RunHud | P1 |
| HUD mostra level | PASS |  |  | RunHud | P2 |
| HUD mostra kills | PASS |  |  | RunHud | P2 |
| `LevelUpPanel` mostra textos via `tr()` | PASS |  |  | localization/UI | P1 |
| `ResultPanel` mostra textos via `tr()` | PASS |  |  | localization/UI | P1 |
| Feedbacks mostram textos via `tr()` | PASS |  |  | feedback/UI | P2 |
| Nenhuma label fica vazia | PASS |  |  | UI geral | P0 |
| Chave ausente aparece como key, nao quebra | PASS |  |  | localization | P2 |
| CSV de localization continua importado | PASS |  |  | `data/localization/translation.csv` | P1 |

## J. Debug / dev-only

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Logs verbosos nao aparecem por padrao | NOT TESTED |  |  | DeveloperAuditLogger | P1 |
| `DebugOverlay` nasce desligado | NOT TESTED |  |  | DebugRoot / overlay | P1 |
| `PrototypeToolsPanel` abre/fecha com F3 | NOT TESTED |  |  | debug tools | P2 |
| `RuntimeTreeSnapshot` funciona com F4 | NOT TESTED |  |  | debug tools | P2 |
| Debug tools nao alteram gameplay sem acao explicita | NOT TESTED |  |  | debug tools | P1 |
| Console nao fica poluido com COMBAT/SPAWN/ANIMATION por padrao | NOT TESTED |  |  | logger channels | P1 |

## K. Stress test manual minimo

| Item | Status | Observacao | Evidencia | Arquivo/sistema afetado | Prioridade |
|---|---|---|---|---|---|
| Rodar alguns minutos sem erro de console | NOT TESTED |  |  | runtime geral | P0 |
| Gerar varios Goblins | NOT TESTED |  |  | enemy spawn/pooling | P1 |
| Gerar varias moedas | NOT TESTED |  |  | drops/pooling | P1 |
| Atacar repetidamente | NOT TESTED |  |  | weapon/hitbox pooling | P1 |
| Usar dash em horda | NOT TESTED |  |  | dash/combat | P1 |
| Tomar dano varias vezes | NOT TESTED |  |  | player hurt flow | P1 |
| Fazer multiplos level-ups | NOT TESTED |  |  | run progression | P1 |
| Sem moeda presa no mapa | NOT TESTED |  |  | CoinDrop | P1 |
| Sem hitbox presa no mapa | NOT TESTED |  |  | DirectionalAttackHitbox | P1 |
| Sem visual de ataque preso | NOT TESTED |  |  | GaiaAttackVisualController | P2 |
| Sem FloatingCombatText reaparecendo com texto/cor errados | NOT TESTED |  |  | WorldFeedbackLayer / text pooling | P2 |
| Sem Goblin reutilizado em estado morto | NOT TESTED |  |  | enemy pooling | P1 |
| Sem `enemy_died` duplicado | NOT TESTED |  |  | events / enemy death | P0 |
| Sem queda perceptivel extrema por debug/log | NOT TESTED |  |  | performance / dev-only | P2 |

## Blockers recomendados

Considere `BLOCKER` quando houver qualquer um destes casos:

- `RunScene` nao carrega
- missing files
- crash ou erro recorrente no console
- Gaia nao move
- ataque da Gaia nao causa dano
- Goblin nao spawna ou nao morre
- level-up nao fecha ou nao aplica upgrade
- moeda nao coleta ou entra no resultado sem coleta
- save/result falha
- pooling deixa entidade em estado sujo evidente

## Itens que podem virar follow-up

Use `NEEDS FOLLOW-UP` quando:

- o fluxo principal funciona, mas ha custo/performance suspeito
- o problema aparece so em stress prolongado
- a ferramenta debug funciona, mas com ruido visual ou ergonomia ruim
- a evidencia e insuficiente para fechar como `PASS` ou `FAIL`
