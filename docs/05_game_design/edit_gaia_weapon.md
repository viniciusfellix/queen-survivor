# Como editar a arma inicial da Gaia

Arquivo principal:

```txt
res://data/weapons/weapon_gaia_initial.tres
```

## Cooldown

Campo:

```txt
cooldown_seconds
```

Exemplo:

```txt
2.0
```

Menor = ataca mais rápido.

## Posição do visual

Campo:

```txt
attack_visual_offset
```

Controla onde o PNG/visual aparece em relação à Gaia.

## Posição da hitbox

Campo:

```txt
attack_hitbox_offset
```

Controla onde a área real de dano fica.

## Tamanho da hitbox

Campo:

```txt
attack_hitbox_radius
```

Quanto maior, mais fácil acertar.

## Tempo da hitbox

Campo:

```txt
attack_hitbox_lifetime
```

Tempo que a hitbox fica ativa.

## Dano físico

Arquivo:

```txt
res://data/weapons/components/gaia_initial_physical.tres
```

Campo:

```txt
amount
```

## Dano mágico

Arquivo:

```txt
res://data/weapons/components/gaia_initial_magical.tres
```

Campo:

```txt
amount
```

## Observação sobre alinhamento do placeholder

O placeholder atual é uma elipse/meia elipse na ponta do ataque. Portanto, é normal precisar ajustar:

```txt
attack_visual_offset
attack_hitbox_offset
attack_hitbox_radius
```

A hitbox não precisa ficar exatamente em cima do desenho. Ela precisa cobrir a área que deve causar dano, inclusive o caminho do golpe.
