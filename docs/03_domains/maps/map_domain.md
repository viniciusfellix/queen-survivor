# Domínio — Mapas

## Arquivos principais

```txt
definitions/MapDefinition.gd
data/maps/map_test_arena_10min.tres

Responsabilidade

O domínio de mapas define os dados configuráveis do mapa usado pela run.

No momento, o primeiro mapa é uma arena infinita simples de 10 minutos.

MapDefinition

Campos atuais:

id
display_name_key
description_key
duration_seconds
victory_multiplier
victory_bonus
Mapa atual
res://data/maps/map_test_arena_10min.tres

Configuração oficial:

duration_seconds = 600
victory_multiplier = 2.0
victory_bonus = 0
Testes

Para testar vitória rapidamente, é permitido alterar temporariamente:

duration_seconds = 30

ou:

duration_seconds = 60

Depois do teste, voltar para:

duration_seconds = 600
Recompensa de vitória

A recompensa de vitória depende do mapa.

Fórmula:

final_money_reward = (run_coins_collected × victory_multiplier) + victory_bonus
Recompensa de derrota

Na derrota, o mapa não aplica multiplicador.

Fórmula:

final_money_reward = run_coins_collected
Futuro

O domínio de mapas poderá evoluir para incluir:

spawn timeline;
eventos de mapa;
duração 10/15/20/30 minutos;
multiplicadores por mapa;
bônus por dificuldade;
bioma;
música;
objetivos especiais;
regras especiais.
