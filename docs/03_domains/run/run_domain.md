# Domínio — Run

`RunState` guarda dados temporários: mapa, Queen, tempo, flags, XP, nível, moedas, kills, dano, causa de morte e reward final. `RunController` orquestra eventos, level-up e encerramento. `RunQuery` bloqueia efeitos durante pausa, ending ou resultado final.

`is_ending` é essencial para impedir dano/drop/XP posterior enquanto a animação/espera da derrota ainda acontece.
