# Como editar mapa, duração e recompensas

## Arquivo principal

```txt
res://data/maps/map_test_arena_10min.tres
Duração do mapa

Campo:

duration_seconds

Valor oficial do primeiro mapa:

600

Isso equivale a 10 minutos.

Para testar rapidamente:

30
60

Depois dos testes, voltar para:

600
Multiplicador de vitória

Campo:

victory_multiplier

Exemplo:

2.0

Se o jogador coletar 10 moedas e vencer:

10 × 2.0 = 20
Bônus de vitória

Campo:

victory_bonus

Exemplo:

5

Se o jogador coletar 10 moedas, o multiplicador for 2 e o bônus for 5:

final_money_reward = (10 × 2) + 5
final_money_reward = 25
Derrota

Na derrota não existe multiplicador.

final_money_reward = moedas_coletadas

Exemplo:

moedas_coletadas = 10
final_money_reward = 10
Moeda não coletada

Moeda no chão não conta.

Se o jogador matou inimigos, mas não pegou a moeda, ela não entra no resultado.

Nome e descrição do mapa

No MapDefinition:

display_name_key = map.test_arena_10min.name
description_key = map.test_arena_10min.description

Os textos ficam em:

res://data/localization/pt_br.json

Chaves atuais:

"map.test_arena_10min.name": "Arena de Teste",
"map.test_arena_10min.description": "Arena infinita simples de 10 minutos."

Checklist de teste

Depois de editar o mapa:

O timer mudou no debug?
A vitória acontece no tempo configurado?
O resultado aparece?
O multiplicador está correto?
O bônus está correto?
A derrota ignora multiplicador?
Moeda não coletada fica fora do total?
