# Domínio — Player / Gaia

`PlayerController` (`class_name PlayerController`) inicializa `PlayerRuntimeState`, lê input do `InputManager` (que usa o Input Map nativo), move Gaia, encaminha mira, recebe dano pela `PlayerHurtbox`, aplica defesa/invencibilidade/morte e processa upgrades do player ou envia upgrades à arma.

## Colisão one-way Gaia ↔ inimigo

A Gaia **não colide** com `EnemyBody` (export `collide_with_enemy_bodies`, default `false`): `_configure_enemy_body_collision()` remove `EnemyBody` da máscara da Gaia no `_ready`, eliminando empurrão/teleporte em aglomerados. Os inimigos seguem colidindo com a Gaia e escorregando (`player_body_slide`).

## Dados editáveis

`queen_gaia.tres` contém atributos base, arma inicial, visual e `hurtbox_areas`. A hurtbox atual usa cápsula `radius=23`, `height=102`, offset `(0,41)`.

## Dano recebido

Ao sofrer dano efetivo, Gaia reduz HP, pisca vermelho, mostra texto flutuante, ativa invencibilidade e publica `player_damaged`.

## Separação entre facing e mira

A aparência horizontal acompanha movimento. A arma aponta pela mira livre.
