# ADR 0003 — Aim Direction não controla o facing visual da Gaia

## Status

Aceita.

## Contexto

A Gaia possui movimento separado da mira. A mira será usada pela arma direcional híbrida, controlada por mouse ou analógico direito.

Durante os testes iniciais, o corpo da Gaia estava virando conforme a posição do mouse. Isso confundia a função visual da personagem com a função de mira/ataque.

## Decisão

A Gaia usa duas direções diferentes:

- `aim_direction`: direção da mira/ataque;
- `facing_direction`: direção visual do corpo.

O `aim_direction` é atualizado pelo mouse ou analógico direito.

O `facing_direction` é atualizado pelo movimento horizontal da personagem.

## Consequências

- O jogador pode andar para um lado e atacar para outro.
- A arma futura usará `aim_direction`.
- O visual da personagem usará `facing_direction`.
- O Spine não decide mira nem movimento.
- A animação da Gaia fica mais coerente com o deslocamento físico.
