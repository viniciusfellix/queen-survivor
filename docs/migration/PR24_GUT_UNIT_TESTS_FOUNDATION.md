# PR24 - Gut Unit Tests Foundation

## Objective

Create a safe first layer of automated tests for the project without changing gameplay, balance, runtime flow, or main scenes.

## Tool choice

This PR does **not** install GUT automatically.

Reason:

- GUT is not currently versioned in the repository.
- This branch must not download external dependencies without explicit confirmation.
- The project still benefits from immediate regression coverage for pure logic.

Because of that, this PR introduces a lightweight native GDScript test runner compatible with Godot 4.x.

## What was added

- `tests/TestCase.gd`
- `tests/run_all_tests.gd`
- `tests/unit/test_damage_resolver.gd`
- `tests/unit/test_reward_resolver.gd`
- `tests/unit/test_spawn_timeline_definition.gd`
- `tests/unit/test_run_state.gd`
- `tests/unit/test_level_up_option_service.gd`
- `tests/README.md`

## Covered systems

### DamageResolver

Coverage added for PR20 behavior:

- `base_damage` always applies;
- physical component applies only on physical weakness;
- magical component applies only on magical weakness;
- components do not apply on neutrality;
- components do not apply on resistance;
- resistance does not reduce base damage;
- multiple weaknesses stack conditional bonus damage;
- breakdown includes base, weakness, resistant, and neutral reasons.

### RewardResolver

Coverage added for:

- victory formula with multiplier and bonus;
- defeat formula using collected coins only;
- safe clamping for negative coin and bonus inputs.

### Spawn Timeline V2

Coverage added for:

- multiple active entries at the same time;
- legacy `get_active_entry()` compatibility behavior;
- legacy fallback fields still producing a usable rule;
- rule window activity and tags.

### RunState

Coverage added for:

- coherent initial state;
- XP progression and remainder carry;
- coin and kill accumulation;
- ending/finished transitions blocking state progression.

### LevelUpOptionService

Coverage added for:

- valid option count;
- duplicate prevention in the same offering;
- stack-limit filtering;
- previous-option avoidance when the pool allows it.

## What was intentionally not tested yet

These systems remain outside this first foundation because they depend heavily on scenes, physics, runtime nodes, signals, or pooled visuals:

- `PlayerController`
- `EnemyBase`
- `EnemySpawner`
- `DirectionalAttackHitbox`
- `EnemyAttackHitbox`
- `CoinDrop`
- `RunScene`
- HUD and combat visuals

## How to run

With a Godot 4.x executable available locally:

```powershell
godot4 --headless --path . --script res://tests/run_all_tests.gd
```

If the executable name/path differs locally, replace `godot4` with the proper binary path.

## Why this is a good first step

This gives the project automated protection exactly where the architecture is strongest today: pure calculation and data-driven logic.

It also avoids forcing a plugin decision before the team is ready.

## Recommended next tests

1. add payload serialization tests for `RunResultPayload`;
2. add deterministic tests around spawn rule runtime state if that logic is extracted further;
3. add scene-backed integration tests once the team decides whether to adopt GUT;
4. add smoke tests for localization keys and upgrade pool data validity.

## Limitations

- The native runner is intentionally small.
- It is not a full plugin ecosystem like GUT.
- It does not replace future integration tests.
- It depends on a local Godot 4.x executable being available on the machine.

## Runtime impact

None.

This PR adds only test and documentation files. No gameplay logic, balance, save flow, reward flow, or runtime scene wiring was changed.
