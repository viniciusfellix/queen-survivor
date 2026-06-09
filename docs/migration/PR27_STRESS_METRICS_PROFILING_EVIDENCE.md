# PR27 - Stress Metrics Profiling Evidence

## Objective

Add visible technical metrics to `StressRunScene` so the user can observe horde pressure in real time before making any optimization decision.

## What this PR adds

- `res://ui/debug/StressMetricsOverlay.gd`
- `res://ui/debug/StressMetricsOverlay.tscn`
- overlay instanced only in `res://scenes/test/StressRunScene.tscn`
- updated stress guide
- profiling results template

## Why this is safe

- `Main.gd` was not changed
- official `RunScene.tscn` was not changed
- official HUD was not changed
- the overlay only reads debug data
- no spawn, combat, coin, save, reward, or result logic was changed

## Metrics shown

- FPS
- process time
- physics process time
- node count
- object count
- run time
- enemies alive
- total spawned
- active wave count
- active rule count
- effective global max alive
- drops alive
- pool free total
- pool scene count
- active wave IDs
- active rule keys
- pool summary by free-node key

## Toggle behavior

- default: visible in `StressRunScene`
- `F6`: hides/shows the overlay

This toggle exists only because the overlay is instantiated only in the technical stress scene.

## How to use

1. open `res://scenes/test/StressRunScene.tscn`
2. run the scene directly
3. watch the overlay while the horde ramps up
4. compare overlay values with Godot profiler/monitors
5. record results in `docs/testing/STRESS_PROFILING_RESULTS_TEMPLATE.md`

## Files altered

- `res://scenes/test/StressRunScene.tscn`
- `res://docs/testing/HORDE_STRESS_TEST_GUIDE.md`

## Files created

- `res://ui/debug/StressMetricsOverlay.gd`
- `res://ui/debug/StressMetricsOverlay.tscn`
- `res://docs/testing/STRESS_PROFILING_RESULTS_TEMPLATE.md`
- `res://docs/migration/PR27_STRESS_METRICS_PROFILING_EVIDENCE.md`

## Runtime impact

The overlay updates on a controlled interval and exists only in the stress scene.

It is observability tooling, not optimization.
