# PR23 - HUD Settings Polish

## Objetivo

Melhorar a leitura da HUD do prototipo e preparar hooks simples para settings futuros, sem alterar gameplay, dano, spawn, balanceamento, save, reward ou result.

## Estado anterior da HUD

Antes desta PR, a HUD ja exibia:

- HP;
- XP;
- level;
- moedas;
- kills;
- timer;
- cooldown da arma;
- mensagem geral da run.

Pontos ainda fracos para o prototipo:

- o cooldown do dash nao aparecia de forma clara;
- nao havia leitura simples da wave ativa;
- a HUD fazia buscas repetidas por player/run a cada refresh;
- os exports de sensibilidade de mira existiam no `PlayerController`, mas ainda nao tinham hook centralizado.

## Melhorias feitas

### HUD

Foi mantida a estrutura atual e adicionados:

- bloco simples de cooldown do dash na `RunHud`;
- label opcional de wave ativa para debug/prototipo;
- cache de referencias runtime para reduzir buscas repetidas;
- refresh aproveitando `get_debug_data()` ja existente no player e na run.

O cooldown do dash usa apenas leitura de:

- `dash_cooldown_timer`;
- `dash_cooldown_seconds`.

Sem alterar a logica real do dash.

### Wave info

Foi adicionada exibicao opcional de wave ativa via `EnemySpawner.get_debug_data()`.

O HUD mostra:

- ids das waves ativas;
- contagem de waves ativas.

Isso foi mantido como informacao de prototipo/debug, nao como UI final.

### Hooks de settings

Foi preparada base minima para settings futuros:

- `InputManager.configure_aim_settings(mouse, analog)`;
- `PlayerController.set_mouse_aim_sensitivity(value)`;
- `PlayerController.set_analog_aim_sensitivity(value)`;
- `PlayerController.set_aim_indicator_enabled(is_enabled)`.

## Sensibilidade de mira

Os valores de sensibilidade agora sao encaminhados para o `InputManager` como hook de configuracao.

Importante:

- o sistema atual de mira e direcional/normalizado;
- por isso, apenas multiplicar sensibilidade hoje nao muda o feel de forma correta;
- os valores ficam preparados para integracao futura com menu/settings sem alterar o comportamento atual.

Em resumo:

- hook preparado: sim;
- aplicacao real no feel da mira: adiada de proposito.

## Arquivos alterados

- `autoloads/InputManager.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `visual/characters/gaia/GaiaVisualController.gd`
- `ui/hud/RunHud.gd`
- `ui/hud/RunHud.tscn`
- `data/localization/translation.csv`

## Arquivos criados

- `docs/migration/PR23_HUD_SETTINGS_POLISH.md`

## O que nao foi alterado

- DamageResolver;
- DamagePayload;
- regra de dano da PR20;
- combat/hitbox/hurtbox;
- indicador de aim da PR21 como comportamento visual base;
- Spawn Timeline V2 como logica;
- spawn rates;
- wave resources;
- cooldown real da arma;
- cooldown real do dash;
- moedas/economia;
- XP/level-up rules;
- save/reward/result.

## Limpeza dentro do dominio

Nao houve remocao agressiva de nodes/scripts.

Foi feita limpeza funcional leve:

- cache de referencias runtime na HUD;
- leitura read-only de wave info no spawner;
- consolidacao dos hooks de settings no `InputManager`/`PlayerController`.

## Testes manuais

1. Abrir projeto no Godot.
2. Confirmar que nao ha missing files.
3. Rodar pelo Play principal.
4. Confirmar `RunScene`.
5. Confirmar HUD visivel.
6. Confirmar HP atualizando.
7. Confirmar XP/level atualizando.
8. Confirmar moedas atualizando.
9. Confirmar kills atualizando.
10. Confirmar timer atualizando.
11. Confirmar cooldown da arma.
12. Confirmar cooldown do dash.
13. Confirmar level-up.
14. Confirmar ResultPanel.
15. Confirmar textos/localizacao sem key quebrada.
16. Confirmar indicador de aim continua funcionando.
17. Confirmar ataque/dano da PR20.
18. Confirmar waves/spawn da PR22.
19. Confirmar moeda/save/result.
20. Confirmar console sem erro novo.

## Riscos e pendencias

- a wave exibida na HUD e informacao tecnica de runtime, nao UI final de design;
- sensibilidade de mira ficou preparada como hook, mas ainda nao altera o feel por causa do modelo direcional atual;
- se futuramente o menu de settings nascer, ele ja pode ligar nesses metodos sem inventar outro contrato.
