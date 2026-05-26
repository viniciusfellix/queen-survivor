# Editar a Arma Inicial da Gaia

## Resources envolvidos

```text
weapon_gaia_initial.tres
gaia_initial_physical.tres
gaia_initial_magical.tres
attack_area_gaia_initial_primary.tres
```

## Configuração aprovada

```text
Cooldown: 2.0
Hitbox Offset: 160
Area: rectangle size=(90,300), offset=(0,0)
Components: physical:3, magical:3
```

## Alterar dano

Edite o component físico ou mágico. Contra o Goblin atual, cada componente recebe bônus de fraqueza de 50%.

## Alterar forma/alcance

Edite `AttackAreaDefinition`, valide centro e bordas com collision shapes visíveis e confirme que inimigos fora da área não são atingidos.

## Upgrade de escala

```text
ID: upgrade_weapon_attack_area_scale_percent
Type: weapon_attack_area_scale_percent
Value Float: 10.0
```

O antigo upgrade de raio não é válido.
