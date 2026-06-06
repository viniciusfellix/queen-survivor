# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Queen Survivor** — a Vampire-Survivors-style survivor-like built in **Godot 4.6.1** (Mobile renderer; `d3d12` rendering device on Windows). The current prototype is **Module 1**: the Queen *Gaia*, an infinite arena (official 10-minute run), and the modular Hitbox/Hurtbox combat system.

This repo is **heavily documented in `docs/`** (in Portuguese). Treat `docs/` as the source of truth and read it before changing a system — start with [`docs/README.md`](docs/README.md), then the relevant `01_architecture/`, `02_lifecycles/`, and `03_domains/` files. `05_game_design/` explains safe balance editing; `06_reference/file_responsibilities.md` maps files to responsibilities.

## Critical: custom Godot build required

Visual scenes use Esoteric Software's `SpineSprite` type (`godot-spine` runtime — see the parent folder). There is no addon/`.gdextension` providing it, so the project must be opened with a **custom Spine-enabled Godot 4.6.1 editor binary**. A stock build fails to load Spine character scenes. Don't "fix" missing-`SpineSprite` errors by editing scenes — the binary is the issue.

## Running & testing

There is **no test suite, build script, or linter**. Development happens inside the Godot editor.

- **Main scene:** `scenes/Main.tscn` (`run/main_scene` uid → loads the initial scene via `Main.gd`).
- **Gameplay prototype:** play `gameplay/test/TestGaiaScene.tscn` (F6) — the real arena where player, camera, spawners, run controller, and HUD are wired. Best scene for gameplay changes.
- **Regression:** before closing any work, run the manual checklist in [`docs/08_testing/regression_module_1.md`](docs/08_testing/regression_module_1.md). Validate combat shapes with **Debug > Visible Collision Shapes**.
- `remove_gd_comments.ps1` is a maintenance script that strips comments/blank lines into a backup folder — a release/cleanup step, **not** part of normal development. Do not run it casually.

## Architecture

**Core principle: gameplay decides, visual represents.** Spine/visual scripts never compute damage, XP, reward, progression, or offensive collision.

Preferred dependency direction (see [`docs/01_architecture/dependency_rules.md`](docs/01_architecture/dependency_rules.md)):

```
Definitions / Resources  →  Gameplay Controllers  →  State & Events  →  UI & Visual
```

### Resources vs Runtime (data-driven)

- **`definitions/`** — `Resource` classes (`*Definition`) holding designer-editable config: `QueenDefinition`, `EnemyDefinition`, `WeaponDefinition`, `CombatShapeDefinition`, `AttackAreaDefinition`, `HurtboxAreaDefinition`, `EnemyAttackDefinition`, `UpgradeDefinition`, `UpgradePoolDefinition`, `MapDefinition`, `SpawnTimelineDefinition`, `CoinDropDefinition`.
- **`data/`** — the actual `.tres` instances (enemies, queens, weapons, upgrades, maps, spawn_timelines, drops, localization).
- **`runtime/`** — temporary per-run state objects (`RunState`, `PlayerRuntimeState`, `SaveData`): HP, XP, coins, cooldowns, stacks, in-progress result. Runtime **never mutates source resources**; duplicate a definition if a component needs run-time modification.
- **Single source rule:** generic scenes execute behavior; resources supply content. `EnemyBase.tscn` does not embed a specific `EnemyDefinition` — the Goblin receives `enemy_chaser_basic.tres` at spawn. For balancing, **edit the `.tres` before touching a script.**

### Autoloads (singletons)

Registered in `project.godot`, scripts in `autoloads/` (see [`docs/01_architecture/autoloads.md`](docs/01_architecture/autoloads.md)):

- **`GameEvents`** — gameplay/UI/persistence **event bus**. It publishes occurrences; it does not run domain logic. Don't add speculative signals with no real emitter+consumer flow. Signal catalog in [`docs/01_architecture/event_bus.md`](docs/01_architecture/event_bus.md).
- **`App`** (title/version/boot log), **`LocalizationManager`** (`get_text(key)` over JSON in `data/localization/`), **`InputManager`** (movement, aim, last valid direction), **`SaveManager`** (JSON save load/apply/persist), **`DeveloperAuditLogger`** (channel-based technical logging — route operational logs here; keep verbose channels off by default).

### Combat (modular Hitbox/Hurtbox)

Combat uses **real physics `Area2D` regions**, not radius/distance math. Three distinct responsibilities — never reuse `BodyCollision` to decide damage:

- `BodyCollision` (`CollisionShape2D` under `CharacterBody2D`) — physics/blocking only.
- **Hitbox** (`Area2D`) — detects hurtboxes and deals damage.
- **Hurtbox** (`Area2D`, `HurtboxComponent`) — vulnerable region, forwards damage to the owner's `receive_damage()`.

Damage math is centralized in static services (no duplication across entities): **`DamageResolver`**, **`RewardResolver`**, **`LevelUpOptionService`**. Flow: `Hitbox → Hurtbox → receive_damage() → DamageResolver → feedback/death/reward`. Geometry comes from `CombatShapeDefinition` (id, enabled, shape, offset, rotation), specialized by `AttackAreaDefinition` / `HurtboxAreaDefinition`. Runtime shapes are instanced as `RuntimeHurtboxShape_*` / `RuntimeEnemyAttackShape_*` children.

**Collision layers** (`project.godot`, full table in [`docs/01_architecture/collision_layers_and_combat_shapes.md`](docs/01_architecture/collision_layers_and_combat_shapes.md)): 1 World, 2 PlayerBody, 3 EnemyBody, 4 PlayerAttackHitbox, 5 EnemyHurtbox, 6 EnemyAttackHitbox, 7 PlayerHurtbox, 8 DropPickup. Wiring: PlayerAttackHitbox `layer 4 / mask 5`; EnemyAttackHitbox `layer 6 / mask 7`.

**Removed terms — do not reintroduce:** `hit_radius`, `attack_hitbox_radius`, `weapon_hitbox_radius_flat`, `contact_damage_radius`, manual distance damage, or `contains_local_point` for impact resolution. If you rename a system, grep for the old names and confirm zero residual references.

### Gameplay, UI, Visual

- **`gameplay/`** — runtime controllers grouped by domain: `player/` (`PlayerController`, dash), `enemies/` (`EnemyBase`), `weapons/` (`GaiaInitialWeaponController`, `DirectionalAttackHitbox`), `combat/` (resolver, payload, hurtbox), `run/` (`RunController`, `RewardResolver`, `RunQuery`, result payload), `spawners/` (`EnemySpawner`), `drops/`, `camera/`, `arena/`, `level_up/` (`LevelUpOptionService`).
- **`ui/`** — `hud/`, `feedback/` + `world_feedback/` (floating combat text), `level_up/`, `result/`, `debug/` (overlay, prototype tools panel).
- **`visual/`** — Spine adapters/controllers. Shared bases `SpineAnimationAdapterBase` and `SpineVisualControllerBase` (`visual/spine/`); Gaia/Goblin/weapon specializations build on them. Before adding repeated logic, check these bases (also `CombatShapeDefinition`, `HurtboxComponent`).
- **`core/`** — `constants/` enums (`DamageTypes`, `UpgradeTypes`, `GameplayStateTypes`, `DeveloperLogChannels`) and `debug/` (`RuntimeTreeSnapshot`).

### Runtime scene tree

`Main.tscn → CurrentSceneRoot → TestGaiaScene.tscn`. The test scene holds `RuntimeRoot` (PlayerGaia, EnemyBase, DropRoot, EnemySpawner, RunController, DropController), Camera2D, and UI layers (RunHud, feedback layers, DebugOverlay, LevelUpPanel, ResultPanel). Full tree in [`docs/01_architecture/scene_architecture.md`](docs/01_architecture/scene_architecture.md).

## Run rules (game design)

- XP enters the run's level-up bar directly. Coins are **physical drops** — counted only when collected, lost if left on the map.
- Victory: `final_money = (coins_collected × victory_multiplier) + victory_bonus`. Defeat: `final_money = coins_collected`.
- Gaia's initial weapon aims by **mouse/right-stick**, not at the nearest enemy, and deals **hybrid physical + magical** damage. The Goblin is weak to physical and magical (+50% weakness).

## Conventions

- **Explicit static typing everywhere** (`var x: float = 0.0`, `func f(a: int) -> void:`).
- Comments and `##` doc-comments are written **in Portuguese**, matching the codebase. Group `@export`s and document them.
- `addons/` is vendored (only `godot_context_exporter`) — don't edit it. `_audit_export/` and `tools/audit/` are generated/diagnostic artifacts.
- All user-facing text must go through localization keys (`LocalizationManager`).
- A feature is "done" only after: structural audit, inline comments, regression, and documentation/ADR updates (`docs/04_decisions/`).
