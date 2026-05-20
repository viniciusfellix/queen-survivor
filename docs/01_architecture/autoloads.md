# Autoloads

## GameEvents

Event bus global. Serve para desacoplar sistemas.

Exemplos de sinais:

- `enemy_died`
- `run_xp_changed`
- `run_coin_collected`
- `run_level_up_started`
- `player_damaged`
- `player_died`

Regra:

```txt
Sistemas comunicam eventos.
Sistemas não devem se acoplar diretamente sem necessidade.
```

## InputManager

Centraliza input de movimento e mira.

Responsabilidades:

- Movimento por WASD/setas.
- Mira por mouse.
- Mira futura por analógico direito.
- `move_direction`.
- `aim_direction`.
- `last_valid_aim_direction`.

## LocalizationManager

Busca textos por chave.

Regra:

```txt
Não hardcodar textos finais em lógica.
Usar chaves como:
queen.gaia.name
weapon.gaia_initial.name
ui.level_up.title
```

## SaveManager

Gerencia save básico. Ainda será mais usado nas próximas etapas.

## App

Boot geral do projeto.
