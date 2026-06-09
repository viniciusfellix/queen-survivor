# Onboarding

## Requisitos

- Godot `4.6.1`
- projeto aberto a partir de `project.godot`

## Primeiro boot

1. Abra o projeto no Godot.
2. Confirme que nao ha `missing files`.
3. Rode pelo play principal para abrir `res://scenes/run/RunScene.tscn`.

## Cenas importantes

- oficial: `res://scenes/run/RunScene.tscn`
- stress: `res://scenes/test/StressRunScene.tscn`
- legado tecnico: `res://gameplay/test/TestGaiaScene.tscn`

## Como rodar testes unitarios

```powershell
& "C:\Users\acer\Documents\Godot\godot-4.2-4.6.1-stable.exe" --headless --path "C:\Users\acer\Documents\Godot\Projects\queen-survivor" --script res://tests/run_all_tests.gd
```

Resultado esperado atual: `19 cases, 0 failures`.

## Como rodar o stress test

1. Abra `res://scenes/test/StressRunScene.tscn`.
2. Rode essa cena diretamente.
3. Use o overlay tecnico para acompanhar FPS e contadores.

## Hygiene local

- nao versionar `.godot/`
- nao versionar `.tmp`
- nao criar zip dentro do repositorio
- nao tratar `TestGaiaScene` como source of truth
- usar docs em `docs/migration/` apenas como historico

## Leituras seguintes

- [Architecture Overview](/C:/Users/acer/Documents/Godot/Projects/queen-survivor/docs/01_architecture/ARCHITECTURE_OVERVIEW.md)
- [Gameplay Systems](/C:/Users/acer/Documents/Godot/Projects/queen-survivor/docs/02_gameplay/GAMEPLAY_SYSTEMS.md)
- [Testing](/C:/Users/acer/Documents/Godot/Projects/queen-survivor/docs/03_testing/TESTING.md)
