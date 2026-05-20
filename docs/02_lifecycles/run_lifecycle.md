# Lifecycle — Run

## Início

```txt
TestGaiaScene carrega
↓
RunController cria RunState
↓
PlayerGaia é instanciada
↓
EnemySpawner é configurado
↓
DropController escuta enemy_died
```

## Durante a run

```txt
RunController incrementa elapsed_seconds
EnemySpawner cria inimigos
Gaia ataca por cooldown
Inimigos perseguem Gaia
Inimigos causam dano por contato
Inimigos morrem
XP entra direto
Moedas podem dropar fisicamente
Level-up pode pausar a run
```

## Level-up

```txt
RunState detecta level ganho
↓
RunController pausa get_tree()
↓
LevelUpPanel abre
↓
Jogador escolhe upgrade
↓
Upgrade aplica
↓
Run despausa
```

## Fim da run

Ainda não implementado. Próxima etapa planejada:

```txt
2G — vitória/derrota/resultado
```

## RunState atual

Guarda:

- `elapsed_seconds`
- `run_xp_gained`
- `current_level`
- `current_level_xp`
- `xp_required_for_next_level`
- `run_coins_collected`
- `run_coins_spent`
- `enemies_killed`
- `level_reached`
- `is_paused`
- `is_victory`
- `is_defeat`
