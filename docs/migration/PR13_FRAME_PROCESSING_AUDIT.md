# PR13 Frame Processing Audit

## Objective

Audit `*_process()` / `*_physics_process()` usage across the project and reduce obviously unnecessary per-frame work without changing gameplay, balance, save, result flow, or runtime composition.

This PR focuses on:

- hot paths that run every frame in gameplay;
- UI/debug scripts that were polling more than necessary;
- repeated group lookups and reflective calls in frame-driven code;
- ensuring debug/dev tools stay available without sitting in the gameplay hot path by default.

## Scripts Inspected

Primary gameplay/runtime targets:

- `gameplay/player/PlayerController.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/run/RunController.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/player/PlayerDashImpactArea.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/camera/FollowCamera.gd`
- `gameplay/combat/HurtboxComponent.gd`

UI/debug/support targets:

- `ui/hud/RunHud.gd`
- `ui/debug/DebugOverlay.gd`
- `ui/debug/DebugEnemyLinkDrawer.gd`
- `ui/debug/tools/PrototypeToolsPanel.gd`
- `ui/feedback/RunFeedbackLayer.gd`
- `ui/world_feedback/WorldFeedbackLayer.gd`
- `ui/world_feedback/FloatingCombatText.gd`
- `core/debug/RuntimeTreeSnapshot.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`
- `visual/spine/SpineVisualControllerBase.gd`
- `visual/spine/SpineAnimationAdapterBase.gd`

## Scripts With `_process()`

- `gameplay/camera/FollowCamera.gd`
- `gameplay/run/RunController.gd`
- `gameplay/spawners/EnemySpawner.gd`
- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
- `ui/debug/DebugEnemyLinkDrawer.gd`
- `ui/debug/DebugOverlay.gd`
- `ui/debug/tools/PrototypeToolsPanel.gd`
- `ui/hud/RunHud.gd`
- `visual/weapons/gaia_initial_weapon/GaiaAttackVisualController.gd`

## Scripts With `_physics_process()`

- `gameplay/combat/EnemyAttackHitbox.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`

## Scripts With `_draw()`

- `gameplay/arena/TestArena.gd`
- `gameplay/drops/CoinDrop.gd`
- `gameplay/enemies/EnemyBase.gd`
- `gameplay/player/PlayerController.gd`
- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
- `ui/debug/DebugEnemyLinkDrawer.gd`

## Hot Path Classification

### Critical hot path

- `gameplay/player/PlayerController.gd`
  - Runs every physics frame.
  - Correctly owns movement, dash, invulnerability, and visual state sync.
  - Debug redraw already gated behind `draw_debug_aim`.

- `gameplay/enemies/EnemyBase.gd`
  - Runs every physics frame for each active enemy.
  - Main survivor-like scaling risk because it can exist hundreds of times.
  - Current work is mostly justified: chase, knockback, slide, body bump, move-and-slide.
  - Repeated target resolution happens only when target is missing, which is acceptable.

- `gameplay/combat/EnemyAttackHitbox.gd`
  - Runs every physics frame only while attack hitbox is active.
  - Uses tracked overlaps and receiver cooldowns instead of world scans.
  - Acceptable for now.

- `gameplay/weapons/attacks/DirectionalAttackHitbox.gd`
  - Runs every physics frame only while active for its short lifetime.
  - Good shape for pooled short-lived object.

- `gameplay/drops/CoinDrop.gd`
  - Runs every physics frame while active.
  - Still does overlap-state refresh through `get_overlapping_bodies()` each tick.
  - This is acceptable for prototype scale, but it remains one of the first candidates for future profiling if coin counts grow aggressively.

### Moderate hot path

- `gameplay/run/RunController.gd`
  - Runs every frame to advance timer and emit `run_timer_changed`.
  - Legitimate coordinator cost, but it fans out to HUD/debug listeners.

- `gameplay/spawners/EnemySpawner.gd`
  - Runs every frame to manage spawn cadence and timeline.
  - Reasonable.
  - Already avoids group scans for alive enemies by using `_alive_enemy_count`.

- `gameplay/weapons/gaia/GaiaInitialWeaponController.gd`
  - Runs every frame for cooldown and fire cadence.
  - Acceptable; resolves roots/player only when references are missing.

- `gameplay/camera/FollowCamera.gd`
  - Runs every frame for smoothing.
  - Expected and lightweight.

### UI / debug

- `ui/hud/RunHud.gd`
  - Was doing full refreshes from both `_process()` and event callbacks.
  - Also used `get_nodes_in_group("player")`, `RunQuery.get_run_controller()`, `has_method`, and `call` during those full refreshes.
  - This was a real avoidable cost.

- `ui/debug/DebugOverlay.gd`
  - Was rebuilding text every frame while enabled.
  - Also reconfigured `DebugEnemyLinkDrawer` every frame even when nothing changed.
  - This was the clearest debug-side waste.

- `ui/debug/DebugEnemyLinkDrawer.gd`
  - Still redraws every frame when enabled.
  - Acceptable because it is explicit debug-only behavior and already sleeps when disabled.

- `ui/debug/tools/PrototypeToolsPanel.gd`
  - Already refreshed on interval, but `_process()` was still left active all the time.
  - Small safe improvement applied.

### Lifecycle / low risk

- `ui/world_feedback/FloatingCombatText.gd`
  - No frame loop; tween-driven.
  - Fine.

- `ui/world_feedback/WorldFeedbackLayer.gd`
  - Event-driven only.
  - Fine.

- `ui/feedback/RunFeedbackLayer.gd`
  - Event-driven only; uses short timers for message lifetime.
  - Fine.

- `core/debug/RuntimeTreeSnapshot.gd`
  - No frame loop.
  - Heavy group counting exists, but only on explicit debug export.

## Small Safe Adjustments Applied

### 1. `ui/debug/DebugOverlay.gd`

Changes:

- added `refresh_interval_seconds` export (`0.20`);
- throttled overlay text rebuild instead of rebuilding every frame;
- cached a lightweight signature for enemy-link config;
- now only calls `DebugEnemyLinkDrawer.configure(...)` when the config actually changes.

Why safe:

- overlay remains functional;
- no gameplay dependency uses this text;
- enemy-link debug still updates when toggled/config changed;
- only debug refresh frequency changed.

### 2. `ui/debug/tools/PrototypeToolsPanel.gd`

Changes:

- panel processing is now disabled while hidden;
- processing is re-enabled when opened with `F3`;
- refresh timer resets when reopening.

Why safe:

- `F3` / `F4` continue to work via `_unhandled_input`;
- hidden panel no longer wakes up every frame just to return early.

### 3. `ui/hud/RunHud.gd`

Changes:

- stopped doing full `_refresh_all()` for simple event callbacks;
- `player_damaged` now updates HP only;
- `run_xp_changed` now updates XP and level only;
- `run_enemy_killed` now updates kills only;
- `run_coins_changed` now updates coins only;
- `run_timer_changed` now updates timer only;
- kept periodic `_process()` refresh as fallback synchronization.

Why safe:

- visible values still update immediately;
- full periodic refresh still exists as safety net;
- no gameplay logic moved into HUD;
- only display-side polling was reduced.

## Remaining Risks / Findings

### Acceptable for now

- `PlayerController.gd` and `EnemyBase.gd` still call visual-controller methods every active frame.
  - This is normal for current architecture.
  - Future optimization should profile method-call overhead only after enemy counts are genuinely high.

- `DebugEnemyLinkDrawer.gd` still uses `get_nodes_in_group("enemy")` inside `_draw()`.
  - That is fine because it is opt-in debug only.

- `FollowCamera.gd` updates every frame.
  - This is expected.

### Worth profiling in a future PR

- `CoinDrop.gd`
  - Per-frame `_refresh_area_overlap_state()` still loops over `get_overlapping_bodies()`.
  - It no longer uses manual distance checks to start magnetism, which is good.
  - Next step, if coin counts become large, is to rely more heavily on entry/exit state and only resync overlaps on reuse/radius changes.

- `RunHud.gd`
  - Still uses group/method lookup in periodic fallback refresh.
  - Good enough now; can later cache player/run references if profiling shows HUD cost.

- `RunController.gd`
  - Emits `run_timer_changed` every frame.
  - Fine for now, but this signal frequency should remain in mind if many listeners accumulate.

- `GaiaInitialWeaponController.gd`
  - Emits cooldown updates every frame.
  - Acceptable now because consumer count is low.

- `EnemyBase.gd`
  - Uses a few `has_method` / `call` checks in body-bump and visual pathways.
  - Not urgent, but candidate for typed contracts later if profiling shows it matters at horde scale.

## Scripts That Already Look Reasonable

- `DirectionalAttackHitbox.gd`
  - active only during lifetime;
  - processing disabled when inactive;
  - debug draw gated.

- `EnemyAttackHitbox.gd`
  - active only when enabled;
  - overlap tracking is local and signal-assisted.

- `GaiaAttackVisualController.gd`
  - short-lived `_process()` with pooling-backed lifecycle;
  - acceptable.

- `FloatingCombatText.gd`
  - tween-driven pooled feedback;
  - no frame loop.

- `PrototypeToolsPanel.gd`
  - now sleeps while hidden.

- `DebugEnemyLinkDrawer.gd`
  - already sleeps while disabled.

## Not Changed Intentionally

- no balance values;
- no damage/HP/cooldown tuning;
- no spawn rules;
- no save/result/reward behavior;
- no runtime scene composition;
- no gameplay state machine changes;
- no debug tool removal.

## Recommended Next Profiling Pass

1. Profile runs with many Goblins and many coins on screen.
2. Measure:
   - enemy physics cost;
   - coin physics cost;
   - HUD/debug signal fan-out cost;
   - visual/Spine cost under horde load.
3. If needed, prioritize:
   - `CoinDrop.gd` overlap refresh strategy;
   - typed/cached contracts in `EnemyBase.gd`;
   - throttling or batching timer/cooldown UI updates.

## Manual Tests

- Open project in Godot.
- Confirm no missing files.
- Run the game from the main Play button.
- Confirm `RunScene` loads.
- Confirm:
  - Gaia moves normally;
  - camera follows Gaia;
  - dash works;
  - Gaia attack works;
  - Goblins spawn, chase, damage, receive damage, and die;
  - XP enters directly;
  - level-up and upgrades still work;
  - coins drop, magnetize, and collect;
  - HUD still updates HP, XP, timer, coins, kills, level, and cooldown;
  - `DebugOverlay` still shows data when enabled;
  - `PrototypeToolsPanel` still opens/closes with `F3`;
  - `RuntimeTreeSnapshot` still exports with `F4`, if it already worked;
  - result / victory / defeat / save still work.
- Let the run continue for a few minutes with many enemies and coins.
- Confirm console has no new errors.

## Final Assessment

This PR found one real gameplay-adjacent waste (`RunHud`) and one clear debug waste (`DebugOverlay`), plus one smaller quality-of-life fix (`PrototypeToolsPanel`). The critical gameplay hot paths are still mostly where they should be for a Godot survivor-like prototype: player, enemies, hitboxes, coins, spawner, and run timer.

The next meaningful optimization target is not a broad rewrite of frame code. It is measured profiling around:

- enemy count scaling;
- coin count scaling;
- event fan-out from timer/cooldown/UI;
- Spine/visual overhead under load.
