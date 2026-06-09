# Stress Testing

## Cena tecnica

- `res://scenes/test/StressRunScene.tscn`

Essa cena e dev-only e nao substitui a `RunScene` oficial.

## Overlay tecnico

`StressMetricsOverlay` mostra:

- FPS
- process time
- physics process time
- contagem de nodes/objects
- inimigos vivos
- total spawnado
- waves/rules ativas
- drops vivos
- resumo do pool

## Resultado oficial registrado

- ~90 inimigos vivos: ~60 FPS medio
- ~120 inimigos vivos: ~50 FPS medio
- ~140 inimigos vivos: ~40 FPS
- ~180 inimigos vivos: ~30 FPS

## Interpretacao

- projeto saudavel para continuar
- meta segura atual: `80-100` inimigos vivos
- acima de `140` deve ser tratado como limite tecnico atual ou futura meta de otimizacao

## Evidencia e formulario

- guia detalhado: `docs/testing/HORDE_STRESS_TEST_GUIDE.md`
- template de resultado: `docs/testing/STRESS_PROFILING_RESULTS_TEMPLATE.md`
