# Domínio — Run

## Arquivos principais

```txt
runtime/RunState.gd
gameplay/run/RunController.gd
```

## RunState guarda

- Tempo.
- XP da run.
- Level.
- XP do level.
- Moedas coletadas.
- Moedas gastas.
- Inimigos mortos.
- Estado de pause.
- Vitória/derrota futura.

## RunController faz

- Escuta morte de inimigos.
- Adiciona XP.
- Conta kills.
- Escuta moedas coletadas.
- Abre level-up.
- Pausa/despausa a run.

## Próxima expansão

2G deve adicionar:

- Timer de 10 minutos.
- Vitória.
- Derrota.
- Resultado.
- Cálculo de recompensa.
