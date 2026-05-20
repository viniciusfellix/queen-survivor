# Glossário

## Queen

Personagem jogável. A primeira Queen implementada é Gaia.

## Gaia

Primeira personagem jogável do protótipo.

## Run

Uma partida temporária. Tudo que acontece durante a run deve ser separado do save permanente.

## RunState

Resource/runtime temporário que guarda o estado vivo da run: tempo, XP obtida, nível, moedas coletadas, inimigos mortos etc.

## SaveData

Estado permanente do jogador. Ainda está básico/stub neste momento.

## XP única

Recurso único usado tanto dentro da run para level-up quanto futuramente fora da run para progressão permanente. Não existe XP global, individual e coletiva separadas.

## Moeda da run

Moeda coletada fisicamente durante a run. Precisa cair no chão, ser puxada por magnetismo e ser coletada. Moeda não coletada é perdida.

## DamageComponent

Um pedaço de dano com tipo e valor. A arma da Gaia usa dois componentes: físico e mágico.

## DamagePayload

Objeto que transporta uma tentativa de dano. Pode carregar dano simples ou lista de componentes.

## DamageResolver

Serviço de cálculo de dano. Resolve defesa, fraqueza, resistência e soma final.

## Visual Adapter

Script que fala diretamente com o Spine. A gameplay não deve chamar `SpineSprite` diretamente.

## Placeholder

Visual temporário usado antes da arte final ou do Spine final.

## Aim Direction

Direção da mira/ataque. Vem do mouse ou analógico direito.

## Facing Direction

Direção visual do corpo da Gaia. Atualmente segue movimento horizontal, não mira.
