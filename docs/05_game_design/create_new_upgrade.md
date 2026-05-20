# Como criar um novo upgrade de level-up

## 1. Criar Resource

Criar em:

```txt
res://data/upgrades/
```

Tipo:

```txt
UpgradeDefinition
```

## 2. Configurar campos

Exemplo:

```txt
id = upgrade_player_move_speed_percent
display_name_key = upgrade.player_move_speed_percent.name
description_key = upgrade.player_move_speed_percent.description
upgrade_type = player_move_speed_percent
value_int = 0
value_float = 10
max_stack_in_run = 999
```

## 3. Adicionar texto

No:

```txt
res://data/localization/pt_br.json
```

Adicionar:

```json
"upgrade.novo.name": "Nome do upgrade",
"upgrade.novo.description": "Descrição do upgrade."
```

## 4. Colocar na pool

Atualmente a pool padrão é carregada em:

```txt
gameplay/run/RunController.gd
```

Função:

```txt
_load_default_upgrade_pool_if_empty()
```

Para novo upgrade aparecer no level-up, adicionar o path na lista default.

Futuro recomendado:

Transformar pool em resource data-driven.
