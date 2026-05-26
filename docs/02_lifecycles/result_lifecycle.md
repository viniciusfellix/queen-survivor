# Lifecycle — Resultado e Save

## Payload

`RunResultPayload` transporta resultado, Queen, mapa, tempo, moedas, recompensa, XP, kills, nível, dano e causa de morte.

## Painel

`ResultPanel` exibe o payload e reage ao status real de persistência. Ele não recalcula recompensa.

## Save

`SaveManager` aplica o payload ao `SaveData`, grava o JSON e emite `run_result_persisted`.

## Debug

Vitória/derrota forçadas pelo painel técnico percorrem o fluxo real e podem modificar o save; resete progressão após testes quando necessário.
