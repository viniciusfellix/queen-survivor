# Domínio — Resultado da Run

## Arquivos principais

```txt
gameplay/run/RunResultPayload.gd
gameplay/run/RewardResolver.gd
ui/result/ResultPanel.gd
ui/result/ResultPanel.tscn

Responsabilidade

O domínio de resultado fecha a run e apresenta ao jogador o resumo.

Ele não deve recalcular gameplay dentro da UI.

RunResultPayload

Carrega os dados finais da run.

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
RewardResolver

Calcula a recompensa final.

Vitória:

final_money_reward = (run_coins_collected × victory_multiplier) + victory_bonus

Derrota:

final_money_reward = run_coins_collected
ResultPanel

Apenas exibe o payload recebido pelo evento:

GameEvents.run_finished(result_payload)

O painel não deve:

calcular recompensa;
aplicar save;
mudar XP;
mudar dinheiro permanente;
decidir vitória;
decidir derrota.
Fluxo
RunController finaliza run
↓
RunController cria RunResultPayload
↓
RewardResolver calcula final_money_reward
↓
GameEvents.run_finished(payload)
↓
ResultPanel exibe payload
Próxima expansão

A próxima etapa deve adicionar:

aplicação do resultado no save;
botão de reiniciar/testar novamente;
possível botão de voltar ao menu;
resumo visual mais bonito;
recordes básicos.
