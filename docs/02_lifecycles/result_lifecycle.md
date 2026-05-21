# Lifecycle — Resultado da Run

## Vitória

```txt
elapsed_seconds >= map_duration_seconds
↓
RunController._finish_victory()
↓
RunState.mark_victory()
↓
RunController._finish_run()
↓
RunController._build_result_payload()
↓
RewardResolver.calculate_final_money_reward(victory=true)
↓
GameEvents.run_finished(result_payload)
↓
ResultPanel mostra vitória
↓
get_tree().paused = true
Derrota
PlayerRuntimeState.current_hp <= 0
↓
PlayerController emite GameEvents.player_died
↓
RunController._on_player_died()
↓
Timer de delay opcional
↓
RunController._finish_defeat(source_id)
↓
RunState.mark_defeat(source_id)
↓
RunController._finish_run()
↓
RunController._build_result_payload()
↓
RewardResolver.calculate_final_money_reward(victory=false)
↓
GameEvents.run_finished(result_payload)
↓
ResultPanel mostra derrota
↓
get_tree().paused = true
Cálculo de recompensa
Vitória
final_money_reward = (run_coins_collected × victory_multiplier) + victory_bonus
Derrota
final_money_reward = run_coins_collected
Moeda não coletada

Moeda física que ficou no chão não entra em:

run_coins_collected

Logo, não entra no resultado.

XP

XP já entra diretamente durante a run e aparece em:

run_xp_gained

A aplicação da XP no save permanente ainda será feita em etapa posterior.

UI

ResultPanel tem process_mode = Always porque a árvore fica pausada ao final da run.

Cuidados técnicos

Ao finalizar a run:

impedir novos level-ups;
impedir nova XP;
impedir nova coleta de moeda;
impedir contagem de kills;
pausar gameplay;
preservar payload para exibição;
não aplicar save ainda.
