# Current Source Of Truth

## Runtime oficial atual

No estado atual do projeto, a cena oficial de runtime passa a ser:

- `res://scenes/run/RunScene.tscn`

Fluxo atual de boot:

- `project.godot`
- `res://scenes/Main.tscn`
- `res://scenes/Main.gd`
- `res://scenes/run/RunScene.tscn`

## Observação importante

`RunScene` passa a ser a composition root oficial da run no boot do jogo.

`TestGaiaScene` continua existindo no projeto como cena técnica/de referência.

## Resources principais que parecem oficiais hoje

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

## Duplicidade identificada: attack area da Gaia

Foi identificada duplicidade ou concorrência aparente entre attack areas da arma inicial da Gaia:

- `res://resources/combat/attack_areas/attack_area_gaia_initial_d.tres`
- `res://data/weapons/attack_areas/attack_area_gaia_initial_primary.tres.tres`

## Decisão desta PR

Esta PR não remove nenhuma dessas duas resources.

Motivo:

- elas podem estar referenciadas por `.tscn` ou `.tres`;
- a exclusão segura precisa ser feita em uma PR própria;
- primeiro precisamos confirmar no editor Godot qual delas deve permanecer como oficial.

## Situação atual da cena do player

`res://gameplay/player/PlayerGaia.tscn` continua sendo a cena atual do player em runtime.

Esta PR não altera:

- exports da cena;
- wiring da arma;
- hurtbox;
- dash;
- visual;
- roots de ataque.

## Situação atual do debug

Os seguintes elementos continuam presentes na cena atual:

- `DebugOverlay`
- `PrototypeToolsPanel`

Na composição oficial atual, esses elementos vivem sob `DebugRoot`.

`DebugRoot` é apenas organização estrutural. Nenhuma dessas ferramentas foi removida nesta etapa.

`DebugOverlay` e `PrototypeToolsPanel` continuam disponíveis no runtime oficial atual.

## Intenção para as próximas etapas

Ordem pretendida após esta PR:

1. `RunScene` mantida como source of truth oficial da run;
2. `TestGaiaScene` mantida como cena técnica/de referência temporária;
3. remoção futura de duplicidades e ambiguidade estrutural remanescente;
4. migração gradual dos sistemas arquiteturais ainda pendentes.
