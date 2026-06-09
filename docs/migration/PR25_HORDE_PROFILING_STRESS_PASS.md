# PR25 - Horde Profiling Stress Pass

## Objective

Create a safe profiling/stress foundation for real horde validation without changing the official runtime scene, official map, official timeline, or gameplay rules.

## What this PR adds

### Stress resources

- `res://data/maps/map_stress_arena.tres`
- `res://data/spawn_timelines/stress_arena/spawn_timeline_stress_arena.tres`
- dedicated wave resources under `res://data/spawn_timelines/stress_arena/`
- dedicated rule resources under `res://data/spawn_timelines/stress_arena/`

### Stress scene

- `res://scenes/test/StressRunScene.tscn`

This scene is technical/dev-only and is not used by boot.

### Documentation

- `res://docs/testing/HORDE_STRESS_TEST_GUIDE.md`
- `res://docs/migration/PR25_HORDE_PROFILING_STRESS_PASS.md`

## Why the official scene was not changed

- `Main.gd` remains untouched;
- `RunScene.tscn` remains the official runtime scene;
- `map_test_arena_10min.tres` remains untouched;
- the official spawn timeline remains untouched.

This keeps stress/profiling completely isolated from normal gameplay flow.

## Stress content structure

The stress content intentionally reuses the existing Goblin enemy and existing run composition.

It adds:

- ramp-up wave;
- overlapping pressure wave;
- denser peak wave;
- boss-style technical probe rule with `max_total_spawns = 1`;
- elite-style low-probability support rules;
- late sustain wave to observe pooling and cleanup.

## Read-only debug expansion

Small read-only helpers were added only for profiling visibility:

- `EnemySpawner.get_debug_data()` now reports active waves/rules, total spawned, alive count, and effective max-alive;
- `DropController.get_debug_data()` now reports alive drop count and current drop setup;
- `PoolManager.get_debug_data()` now reports pooled free-node counts by scene key.

These changes do not alter gameplay logic.

## Risks known in advance

- stress results will still depend on the local machine and renderer mode;
- Goblin visual/Spine cost may dominate results before gameplay scripts do;
- a technical stress scene can reveal pooling bugs that do not show in a normal run;
- this PR intentionally does not optimize speculative hotspots.

## Manual test checklist

1. Open the project in Godot.
2. Confirm no missing files.
3. Run unit tests with:

```powershell
& "C:\Users\acer\Documents\Godot\godot-4.2-4.6.1-stable.exe" --headless --path "C:\Users\acer\Documents\Godot\Projects\queen-survivor" --script res://tests/run_all_tests.gd
```

4. Confirm 0 failures.
5. Run the official game normally and confirm `RunScene` still behaves as before.
6. Open and run `res://scenes/test/StressRunScene.tscn`.
7. Observe FPS, process time, physics time, node/object counts, coins, pooling reuse, and console health.

## Runtime impact

No official runtime path was changed.

This PR adds only separated stress resources, one parallel technical scene, documentation, and read-only debug accessors.
