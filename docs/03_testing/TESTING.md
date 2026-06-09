# Testing

## Estado atual

O projeto usa testes unitarios nativos em GDScript.

- runner: `res://tests/run_all_tests.gd`
- resultado atual conhecido: `19 cases, 0 failures`

## Como rodar

```powershell
& "C:\Users\acer\Documents\Godot\godot-4.2-4.6.1-stable.exe" --headless --path "C:\Users\acer\Documents\Godot\Projects\queen-survivor" --script res://tests/run_all_tests.gd
```

## Suites atuais

- `test_damage_resolver.gd`
- `test_reward_resolver.gd`
- `test_spawn_timeline_definition.gd`
- `test_run_state.gd`
- `test_level_up_option_service.gd`

## Limites atuais

- foco em logica pura
- sem testes de integracao com cena/fisica ainda
- sem dependencia externa instalada automaticamente

## Proximo passo recomendado

- testes de integracao para cenas/fisica quando o conteudo estabilizar
