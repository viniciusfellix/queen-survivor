# Lifecycle — Run

## Início

```txt
TestGaiaScene carrega
↓
RunController cria RunState
↓
PlayerGaia é instanciada
↓
EnemySpawner é configurado
↓
DropController escuta enemy_died
```

## Durante a run

```txt
RunController incrementa elapsed_seconds
EnemySpawner cria inimigos
Gaia ataca por cooldown
Inimigos perseguem Gaia
Inimigos causam dano por contato
Inimigos morrem
XP entra direto
Moedas podem dropar fisicamente
Level-up pode pausar a run
```

## Level-up

```txt
RunState detecta level ganho
↓
RunController pausa get_tree()
↓
LevelUpPanel abre
↓
Jogador escolhe upgrade
↓
Upgrade aplica
↓
Run despausa
```

## Fim da run

Ainda não implementado. Próxima etapa planejada:

```txt
2G — vitória/derrota/resultado
```

## RunState atual

Guarda:

- `elapsed_seconds`
- `run_xp_gained`
- `current_level`
- `current_level_xp`
- `xp_required_for_next_level`
- `run_coins_collected`
- `run_coins_spent`
- `enemies_killed`
- `level_reached`
- `is_paused`
- `is_victory`
- `is_defeat`

## Fim da run

O fim da run agora pode acontecer de duas formas:

### Vitória

```txt
RunController conta elapsed_seconds
↓
elapsed_seconds >= map_duration_seconds
↓
RunState.mark_victory()
↓
RunController monta RunResultPayload
↓
RewardResolver calcula final_money_reward
↓
GameEvents.run_finished é emitido
↓
ResultPanel exibe resultado
↓
get_tree().paused = true

Derrota
Gaia chega a 0 HP
↓
PlayerController emite player_died
↓
RunController agenda derrota
↓
RunState.mark_defeat(source_id)
↓
RunController monta RunResultPayload
↓
RewardResolver calcula final_money_reward
↓
GameEvents.run_finished é emitido
↓
ResultPanel exibe resultado
↓
get_tree().paused = true

Resultado

O resultado é carregado em:

RunResultPayload

Campos principais:

result_type
victory
defeat
queen_id
map_id
elapsed_seconds
survived_seconds
map_duration_seconds
run_coins_collected
victory_multiplier
victory_bonus
final_money_reward
run_xp_gained
enemies_killed
level_reached
damage_dealt
damage_taken
death_cause
Recompensa

A recompensa final é calculada por:

RewardResolver

Vitória:

final_money_reward = (run_coins_collected × victory_multiplier) + victory_bonus

Derrota:

final_money_reward = run_coins_collected
Importante

O ResultPanel apenas exibe o payload.

Ele não calcula recompensa, não altera save e não decide vitória/derrota.


---

# 5. Atualizar `docs/03_domains/run/run_domain.md`

Adicione esta seção no final:

```md
## Timer e finalização da run

O `RunController` agora controla o timer da run com base no `MapDefinition`.

Campos importantes em `RunState`:

```txt
map_id
queen_id
elapsed_seconds
map_duration_seconds
is_finished
is_victory
is_defeat
result_type
death_cause
final_money_reward
Vitória

A vitória acontece quando:

elapsed_seconds >= map_duration_seconds

O fluxo chama:

RunState.mark_victory()

Depois:

RunController._finish_run()
Derrota

A derrota acontece quando GameEvents.player_died é emitido.

O fluxo chama:

RunState.mark_defeat(source_id)

Depois:

RunController._finish_run()
Resultado

O RunController constrói um RunResultPayload.

Esse payload é emitido em:

GameEvents.run_finished(result_payload)

O ResultPanel escuta esse evento e exibe o resumo.

Próxima expansão

A próxima etapa deve fazer o save pós-run:

adicionar run_xp_gained ao total_xp;
adicionar final_money_reward ao dinheiro permanente;
marcar mapa como concluído se vitória;
salvar last_run_summary;
preparar botão simples de reiniciar/testar novamente.
