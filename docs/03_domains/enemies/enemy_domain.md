# Domínio — Inimigos

## Arquivos principais

```txt
definitions/EnemyDefinition.gd
data/enemies/enemy_chaser_basic.tres
gameplay/enemies/EnemyBase.gd
gameplay/enemies/EnemyBase.tscn
gameplay/spawners/EnemySpawner.gd
gameplay/spawners/EnemySpawner.tscn
visual/enemies/goblin_warrior/
```

## EnemyDefinition

Define dados configuráveis do inimigo:

- HP.
- Velocidade.
- Dano de contato.
- Raio de contato.
- Cooldown de contato.
- Tipo de dano de contato.
- Fraquezas.
- Resistências.
- XP.
- Chance de moeda.
- Valor da moeda.
- Visual.

## EnemyBase

Entidade viva do inimigo.

Responsável por:

- Perseguir o player.
- Aplicar dano de contato.
- Receber dano.
- Morrer.
- Emitir evento `enemy_died`.

## EnemySpawner

Cria inimigos ao redor do player.

Configura:

- Cena do inimigo.
- Definition do inimigo.
- Intervalo de spawn.
- Distância de spawn.
- Máximo de inimigos vivos.

## Visual do inimigo

Goblin atual:

```txt
visual/enemies/goblin_warrior/GoblinWarriorVisual.tscn
```

Usa:

- `GoblinWarriorVisualController`
- `GoblinWarriorSpineAdapter`
- `SpineSprite`
