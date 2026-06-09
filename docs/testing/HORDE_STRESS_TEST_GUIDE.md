# Horde Stress Test Guide

## Objective

Provide a repeatable manual stress/profiling flow for Queen Survivors without altering the official runtime scene or official balance content.

## Stress entry point

Use the dedicated scene:

- `res://scenes/test/StressRunScene.tscn`

This scene reuses the normal run composition but points `RunController.map_definition` to:

- `res://data/maps/map_stress_arena.tres`

The official gameplay scene remains:

- `res://scenes/run/RunScene.tscn`

## Why this is separate

- no `Main.gd` changes;
- no official map changes;
- no official timeline changes;
- no official balancing changes;
- stress resources stay isolated from production content.

## Stress scenarios included

The stress map uses a dedicated timeline:

- `wave_00_ramp`: light ramp-up;
- `wave_01_overlap_pressure`: overlapping pressure wave;
- `wave_02_peak`: high density main pressure;
- `wave_03_boss_probe`: simulated boss/elite technical rule set;
- `wave_04_tail_cleanup`: late sustain for pooling/reuse observation.

Rule mix included:

- one 100% spawn rule;
- one low-probability elite-style rule;
- one `max_total_spawns = 1` boss-style technical rule;
- overlapping concurrent waves;
- multiple rules active in the same wave.

## How to run

1. Open the project in Godot.
2. Open `res://scenes/test/StressRunScene.tscn`.
3. Run that scene directly, not the main Play button.
4. Keep debug overlay and verbose channels disabled by default.
5. Observe Godot monitors and profiler during 3 to 5 minutes of play.

## Recommended Godot monitors

Watch at minimum:

- FPS
- Process time
- Physics process time
- Node count
- Object count
- Static memory
- Video memory

If using the Profiler tab, focus on:

- script functions
- `_physics_process`
- `_process`
- spikes during coin bursts
- spikes during level-up pauses/resume

## Read-only debug data already available

### EnemySpawner

`EnemySpawner.get_debug_data()` now exposes:

- `active_wave_ids`
- `active_wave_count`
- `active_rule_keys`
- `active_rule_count`
- `tracked_rule_count`
- `total_spawned`
- `alive_enemy_count`
- `effective_global_max_alive`

### DropController

`DropController.get_debug_data()` now exposes:

- `alive_drop_count`
- `coin_definition_id`
- `drop_root_name`

### PoolManager

`PoolManager.get_debug_data()` now exposes:

- `pooled_scene_count`
- `total_free_nodes`
- `free_count_by_key`

## Probable hotspots to observe

Do not optimize these preemptively. Use them as profiling targets only after evidence:

- `EnemyBase._physics_process`
- `move_and_slide` across many enemies
- Goblin visual/Spine update cost
- `CoinDrop` under large drop bursts
- `EnemyAttackHitbox`
- `DirectionalAttackHitbox`
- `FloatingCombatText`
- HUD refresh under many events
- accidental debug/log activation

## Suggested scenarios

### Minimum scenario

- Run 60 seconds.
- Confirm no missing files or console errors.
- Confirm enemies, coins, HUD, and pooling all behave normally.

### Medium scenario

- Run 2 minutes.
- Allow overlapping waves to start.
- Kill enough enemies to create repeated coin bursts.
- Observe FPS and physics time during combat + coin collection.

### Heavy scenario

- Run full 3 to 5 minutes.
- Stay alive deep into `wave_02_peak` and overlapping late waves.
- Trigger repeated attacks, dashes, pickups, and multiple level-ups.
- Watch for stuck hitboxes, dirty pooled enemies, stuck coins, or console noise.

## Initial result classification

These are starting heuristics, not hard certification limits.

### PASS

- no recurring console errors;
- no missing files;
- no obvious dirty pooled state;
- no stuck coins/hitboxes/visuals;
- stress scene remains playable through peak pressure.

### WARNING

- noticeable but survivable FPS drops during peak overlap;
- physics time spikes that recover quickly;
- coin bursts or level-up transitions causing visible hitching;
- node/object counts growing more than expected but stabilizing.

### BLOCKER

- repeated console errors;
- crashes/freezes;
- pooled enemy returns in broken visual/combat state;
- coins stop collecting correctly;
- hitboxes or visuals remain stuck in world;
- severe frame collapse that prevents meaningful play.

## Suggested observation table

| Scenario | Duration | Avg FPS | Lowest FPS | Physics time | Alive enemies | Coins alive | Notes | Status |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Minimum | 1 min |  |  |  |  |  |  | NOT TESTED |
| Medium | 2 min |  |  |  |  |  |  | NOT TESTED |
| Heavy | 3-5 min |  |  |  |  |  |  | NOT TESTED |

## What not to do in this PR

- do not tune official balance from this stress setup;
- do not point `Main.gd` to the stress scene;
- do not replace the official map/timeline;
- do not optimize code without evidence from actual profiling.

## Next steps after results

If stress is healthy:

1. keep this scene as a regression stress entry point;
2. repeat after future combat/spawn/pooling changes;
3. add captured profiling notes to QA docs.

If stress shows issues:

1. identify the hotspot from profiler data;
2. isolate whether the problem is spawn, enemy physics, coins, visuals, or UI;
3. fix only the evidenced bottleneck in a focused follow-up PR.
