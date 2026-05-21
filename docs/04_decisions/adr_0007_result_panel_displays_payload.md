# ADR 0007 — ResultPanel apenas exibe RunResultPayload

## Status

Aceita.

## Contexto

A run agora pode terminar por vitória ou derrota. Ao terminar, o jogo precisa exibir um resumo ao jogador.

Existe o risco de colocar cálculo de recompensa diretamente na UI, o que misturaria apresentação com regra de gameplay/economia.

## Decisão

O `ResultPanel` não calcula resultado.

O resultado é montado pelo `RunController` e calculado pelo `RewardResolver`.

A UI recebe apenas:

```txt
RunResultPayload

E exibe os dados.

Consequências
A fórmula de recompensa fica fora da UI.
O painel pode ser redesenhado sem quebrar economia.
O save futuro pode consumir o mesmo payload.
Testes de resultado ficam mais simples.
A regra de vitória/derrota fica centralizada no RunController.
Fluxo aprovado
RunController
↓
RewardResolver
↓
RunResultPayload
↓
GameEvents.run_finished
↓
ResultPanel

---
