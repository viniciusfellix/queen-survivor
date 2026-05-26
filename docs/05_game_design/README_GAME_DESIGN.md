# Guia do Game Designer — Resources e Balanceamento

## Objetivo

Este documento orienta edição e criação de conteúdo sem mexer na lógica GDScript já implementada. Antes de alterar `.tres`, faça commit ou backup.

## Regra de ouro

Edite dados no Inspector por resources. Não coloque valores específicos de um inimigo/arma em cenas genéricas quando o resource já é a fonte oficial.

## Nomenclatura de IDs

Use inglês, minúsculas e `snake_case`.

| Conteúdo | Padrão | Exemplo |
|---|---|---|
| Queen | nome | `gaia` |
| Arma | `weapon_<queen>_<nome>` | `weapon_gaia_initial` |
| Componente | `<arma>_<tipo>` | `gaia_initial_physical` |
| Área de arma | `attack_area_<arma>_<parte>` | `attack_area_gaia_initial_primary` |
| Inimigo | `enemy_<função>` | `enemy_chaser_basic` |
| Hurtbox inimiga | `hurtbox_area_<enemy>_<parte>` | `hurtbox_area_enemy_chaser_basic_body` |
| Ataque inimigo | `enemy_attack_<nome>_<ataque>` | `enemy_attack_chaser_basic_contact` |
| Área do ataque | `attack_area_<nome>_<ataque>` | `attack_area_enemy_chaser_basic_contact` |
| Upgrade | `upgrade_<efeito>` | `upgrade_weapon_attack_area_scale_percent` |
| Mapa | `map_<nome>_<duracao>` | `map_test_arena_10min` |

## Localization

Todo texto exibido deve ter chave em `res://data/localization/pt_br.json`. Padrões:

```text
queen.gaia.name / queen.gaia.description
enemy.chaser_basic.name / enemy.chaser_basic.description
weapon.gaia_initial.name / weapon.gaia_initial.description
upgrade.weapon_attack_area_scale_percent.name / .description
map.test_arena_10min.name / .description
```

## `value_int` e `value_float`

| Campo | Quando usar | Exemplos |
|---|---|---|
| `value_int` | quantidade inteira/flat | vida `+10`, cura `+20`, dano `+1` |
| `value_float` | porcentagem/multiplicador | velocidade `+8.0%`, cooldown `-1.5%`, área `+10.0%` |

## Resources centrais editáveis

- `queen_gaia.tres` e sua hurtbox;
- `weapon_gaia_initial.tres`, components e attack area;
- `enemy_chaser_basic.tres`, hurtbox e attack definition;
- resources de upgrades e pool;
- map e spawn timeline;
- coin definition.

## Aprovação de balanceamento

1. altere o resource;
2. execute a cena técnica;
3. ative logs somente quando necessário;
4. valide shapes com `Visible Collision Shapes`;
5. confira dano/upgrades/results;
6. registre o valor aprovado na documentação ou changelog.
