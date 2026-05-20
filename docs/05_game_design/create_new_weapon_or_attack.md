# Como criar nova arma ou ataque

## Arma baseada na Gaia atual

Duplicar:

```txt
res://data/weapons/weapon_gaia_initial.tres
```

Exemplo:

```txt
res://data/weapons/weapon_gaia_alt.tres
```

Alterar:

```txt
id
display_name_key
description_key
cooldown_seconds
attack_visual_offset
attack_hitbox_offset
attack_hitbox_radius
damage_components
```

## Criar componentes de dano

Duplicar:

```txt
res://data/weapons/components/gaia_initial_physical.tres
```

ou criar novo:

```txt
res://data/weapons/components/nova_arma_fire.tres
```

Configurar:

```txt
damage_type
amount
affected_by_weakness
affected_by_resistance
```

## Visual placeholder

Colocar imagem em:

```txt
res://assets/placeholders/weapons/NOME_DA_ARMA/
```

Criar/duplicar visual em:

```txt
res://visual/weapons/NOME_DA_ARMA/
```

## Spine futuro

Colocar assets em:

```txt
res://assets/spine/weapons/NOME_DA_ARMA/
```

Criar:

```txt
SpineSkeletonDataResource
```

Depois ajustar a scene visual.
