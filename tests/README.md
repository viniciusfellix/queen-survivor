# Test Automation Foundation

This project now has a lightweight native test foundation for Godot 4.x that does not require external addons.

## Current approach

- No external dependency was installed in this PR.
- GUT was **not** added automatically because it is not present in the repository and this PR must not download dependencies without confirmation.
- Tests use a small native GDScript runner focused on pure logic.

## Current test suites

- `tests/unit/test_damage_resolver.gd`
- `tests/unit/test_reward_resolver.gd`
- `tests/unit/test_spawn_timeline_definition.gd`
- `tests/unit/test_run_state.gd`
- `tests/unit/test_level_up_option_service.gd`

## Run from Godot editor

1. Open the project in Godot 4.x.
2. Open `res://tests/run_all_tests.gd`.
3. Run the script with a headless-compatible Godot runtime or use the command line flow below.

## Run from command line

Use a Godot 4.x executable:

```powershell
godot4 --headless --path . --script res://tests/run_all_tests.gd
```

If your executable name differs, replace `godot4` with the local Godot 4.x binary path.

## Why this runner exists

It gives the project immediate regression coverage for pure systems while keeping this PR small and dependency-free.

## Future path

If the team decides to adopt GUT later:

1. install GUT manually for Godot 4.x;
2. keep these suites as behavioral references;
3. migrate the native runner suites to GUT incrementally, starting with DamageResolver and SpawnTimeline.
