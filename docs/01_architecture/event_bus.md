# Arquitetura — Event Bus (`GameEvents`)

`GameEvents` reduz acoplamento entre gameplay, HUD, feedback visual, painel final e save.

| Signal | Significado | Consumidores típicos |
|---|---|---|
| `player_damaged` | Gaia sofreu dano efetivo | feedback flutuante/HUD |
| `player_died` | Gaia morreu | RunController |
| `enemy_damaged` | inimigo sofreu dano efetivo | diagnóstico/feedback futuro |
| `enemy_died` | inimigo morreu | RunController/DropController |
| `run_xp_changed` | XP ou nível mudou | HUD |
| `run_enemy_killed` | kill contabilizada | HUD |
| `run_coin_collected` | moeda física coletada | feedback |
| `run_coins_changed` | saldo mudou | HUD |
| `run_level_up_started` | escolha foi aberta | LevelUpPanel/feedback |
| `run_level_up_option_selected` | opção selecionada | RunController |
| `run_level_up_completed` | aplicação finalizada | UI/diagnóstico |
| `run_timer_changed` | timer mudou | HUD |
| `run_finished` | resultado consolidado | ResultPanel/SaveManager |
| `weapon_cooldown_changed` | cooldown mudou | HUD |
| `spine_animation_changed` | animação publicada | DebugOverlay |
| `save_updated` | save alterado | painel técnico |
| `run_result_persisted` | resultado salvo/falhou | ResultPanel |

## Disciplina

Não manter signals sem fluxo real. Quando um sistema for removido ou renomeado, pesquisar emissores e consumidores antes de decidir manter o signal.
