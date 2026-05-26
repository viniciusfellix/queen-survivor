# Arquitetura — Estrutura de Pastas

```text
res://
├── core/debug/                    # audit logger e snapshot runtime
├── data/
│   ├── drops/                     # coin definitions
│   ├── enemies/                   # inimigos, attacks e hurtboxes
│   ├── localization/              # JSON atual
│   ├── maps/                      # mapas
│   ├── queens/                    # Queens e hurtboxes
│   ├── spawn_timelines/           # waves
│   ├── upgrades/                  # upgrades
│   ├── upgrade_pools/             # pools
│   └── weapons/                   # armas, components e attack areas
├── definitions/                   # classes Resource/tipos
├── gameplay/
│   ├── arena/
│   ├── camera/
│   ├── combat/
│   ├── drops/
│   ├── enemies/
│   ├── player/
│   ├── run/
│   ├── spawners/
│   ├── test/
│   └── weapons/
├── scenes/                        # Main
├── ui/                            # HUD, feedback, level-up, result, debug
└── visual/                        # Spine, Gaia, Goblin e arma
```

## Conteúdo de combate novo

Estrutura recomendada, respeitando as referências reais existentes no projeto:

```text
data/enemies/
├── enemy_chaser_basic.tres
├── hurtboxes/hurtbox_area_enemy_chaser_basic_body.tres
└── attacks/
    ├── enemy_attack_chaser_basic_contact.tres
    └── attack_area_enemy_chaser_basic_contact.tres

data/queens/
├── queen_gaia.tres
└── hurtboxes/hurtbox_area_gaia_body.tres

data/weapons/
├── weapon_gaia_initial.tres
├── components/gaia_initial_physical.tres
├── components/gaia_initial_magical.tres
└── attack_areas/attack_area_gaia_initial_primary.tres
```

Não mover resources apenas para adequar pastas à documentação se a referência atual já funciona; faça reorganizações somente em etapa própria com regressão.
