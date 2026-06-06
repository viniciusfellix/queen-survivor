# Domínio — Run

`RunState` guarda dados temporários: mapa, Queen, tempo, flags, XP, nível, moedas, kills, dano, causa de morte e reward final. `RunController` orquestra eventos, level-up e encerramento. `RunQuery` expõe `get_run_controller`, `get_run_state`, `is_run_ending` e `is_run_finished` (este último usado apenas no callback do `DropController`).

A pausa é **nativa** via `get_tree().paused` — o `RunController` pausa a árvore no level-up e no fim de run, e a UI correspondente roda com `process_mode = ALWAYS`. Não há mais `is_gameplay_blocked` / `is_run_paused` em `RunQuery`, nem as checagens correspondentes nos `_process` / `_physics_process`.

No delay de derrota (0.75s) o mundo **continua rodando**; a pausa só ocorre no `ResultPanel`. `is_run_ending` segue essencial para impedir dano/drop/XP posterior enquanto a espera da derrota acontece.
