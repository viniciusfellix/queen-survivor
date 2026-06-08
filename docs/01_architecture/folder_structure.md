# Arquitetura - Estrutura de Pastas

```text
res://
|-- core/debug/                    # audit logger e snapshot runtime
|-- data/
|   |-- drops/                     # coin definitions
|   |-- enemies/                   # inimigos, attacks e hurtboxes
|   |-- localization/              # translation.csv + imports nativos do Godot
|   |-- maps/                      # mapas
|   |-- queens/                    # Queens e hurtboxes
|   |-- spawn_timelines/           # waves
|   |-- upgrades/                  # upgrades
|   |-- upgrade_pools/             # pools
|   `-- weapons/                   # armas, components e attack areas
|-- definitions/                   # classes Resource/tipos
|-- gameplay/
|   |-- arena/
|   |-- camera/
|   |-- combat/
|   |-- drops/
|   |-- enemies/
|   |-- player/
|   |-- run/
|   |-- spawners/
|   |-- test/
|   `-- weapons/
|-- scenes/                        # Main
|-- ui/                            # HUD, feedback, level-up, result, debug
`-- visual/                        # Spine, Gaia, Goblin e arma
```

## Conteudo de combate novo

Estrutura recomendada, respeitando as referencias reais existentes no projeto:

```text
data/enemies/
|-- enemy_chaser_basic.tres
|-- hurtboxes/hurtbox_area_enemy_chaser_basic_body.tres
`-- attacks/
    |-- enemy_attack_chaser_basic_contact.tres
    `-- attack_area_enemy_chaser_basic_contact.tres

data/queens/
|-- queen_gaia.tres
`-- hurtboxes/hurtbox_area_gaia_body.tres

data/weapons/
|-- weapon_gaia_initial.tres
|-- components/gaia_initial_physical.tres
|-- components/gaia_initial_magical.tres
`-- attack_areas/attack_area_gaia_initial_primary.tres
```

Nao mover resources apenas para adequar pastas a documentacao se a referencia atual ja funciona; faca reorganizacoes somente em etapa propria com regressao.
