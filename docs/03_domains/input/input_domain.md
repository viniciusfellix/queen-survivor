# Domínio — Input

## Arquivo principal

```txt
autoloads/InputManager.gd
```

## Movimento

Ações:

- `move_left`
- `move_right`
- `move_up`
- `move_down`

Por padrão:

- WASD.
- Setas.

## Mira

A mira atual usa mouse.

Futuro:

- Analógico direito.
- Fallback para última direção válida.

## Separação essencial

```txt
move_direction ≠ aim_direction
```

## Facing da Gaia

O corpo da Gaia olha para o lado do movimento horizontal.

## Ataque da Gaia

O ataque usa a direção da mira.

Isso permite:

```txt
andar para esquerda
atacar para direita
```
