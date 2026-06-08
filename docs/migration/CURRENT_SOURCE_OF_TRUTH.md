# Current Source Of Truth

## Runtime oficial atual

A cena oficial de runtime da run e:

- `res://scenes/run/RunScene.tscn`

Fluxo atual de boot:

- `project.godot`
- `res://scenes/Main.tscn`
- `res://scenes/Main.gd`
- `res://scenes/run/RunScene.tscn`

## Estado atual de composicao

- `RunScene` e a composition root oficial atual.
- `TestGaiaScene` continua existindo apenas como cena tecnica legada/de referencia.
- `DebugRoot` concentra `DebugOverlay` e `PrototypeToolsPanel`.
- Essas ferramentas continuam disponiveis para desenvolvimento, mas nao fazem parte do gameplay.

## Resources principais atualmente oficiais

### Mapa / run

- `res://data/maps/map_test_arena_10min.tres`
- `res://data/spawn_timelines/test_arena_10min/spawn_timeline_test_arena_10min.tres`
- `res://data/upgrade_pools/upgrade_pool_gaia_default.tres`

### Queen / player

- `res://data/queens/queen_gaia.tres`
- `res://data/queens/gaia/dash_gaia_basic.tres`

### Arma da Gaia

- `res://data/weapons/weapon_gaia_initial.tres`
- `res://data/weapons/components/gaia_initial_physical.tres`
- `res://data/weapons/components/gaia_initial_magical.tres`

### Inimigo atual

- `res://data/enemies/enemy_chaser_basic.tres`
- `res://data/enemies/enemy_attack_chaser_basic_contact.tres`
- `res://data/enemies/hurtbox_area_enemy_chaser_basic_body.tres`

### Drop / moeda

- `res://data/drops/coin_default.tres`

## Duplicidade identificada na attack area da Gaia

Foi identificada duplicidade aparente entre:

- `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

Essa duplicidade continua documentada, mas nao foi removida. A exclusao segura depende de confirmacao de referencias no editor Godot.

## Observacoes atuais

- `PlayerGaia.tscn` continua sendo a cena de player usada em runtime.
- `RunScene` continua sendo a source of truth oficial para mudancas de composicao da run.
- Mudancas novas de composicao devem acontecer primeiro em `RunScene`, nao em `TestGaiaScene`.
