# Placeholders e Spine

## Regra

Gameplay deve funcionar independentemente de a arte definitiva estar disponível. Placeholders podem validar ataque, shape e UI, enquanto Spine substitui apenas a apresentação visual.

## Spine

- Não colocar dano, cooldown, XP ou morte em animações.
- Controllers visuais recebem estados do gameplay.
- Alterar nomes de animação exige validar idle/run/death e flashes.
- A árvore runtime Spine é compactada pelo snapshot para evitar ruído.

## Attack visual

O visual da arma pode mudar sem alterar a hitbox; sempre ajuste o resource da attack area para coincidir com a percepção visual real do golpe.
