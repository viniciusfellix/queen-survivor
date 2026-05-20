# ADR 0004 — RunState não é Save

## Status

Aceita.

## Decisão

`RunState` guarda estado temporário da partida.

`SaveData` guardará progresso permanente.

## Consequência

Ao fim da run:

- RunState morre.
- Recompensas calculadas são aplicadas ao save.
- Dados permanentes não devem depender de runtime vivo.
