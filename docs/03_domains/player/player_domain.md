# Domínio — Player / Gaia

`PlayerController` inicializa `PlayerRuntimeState`, lê input, move Gaia, encaminha mira, recebe dano pela `PlayerHurtbox`, aplica defesa/invencibilidade/morte e processa upgrades do player ou envia upgrades à arma.

## Dados editáveis

`queen_gaia.tres` contém atributos base, arma inicial, visual e `hurtbox_areas`. A hurtbox atual usa cápsula `radius=23`, `height=102`, offset `(0,41)`.

## Dano recebido

Ao sofrer dano efetivo, Gaia reduz HP, pisca vermelho, mostra texto flutuante, ativa invencibilidade e publica `player_damaged`.

## Separação entre facing e mira

A aparência horizontal acompanha movimento. A arma aponta pela mira livre.
