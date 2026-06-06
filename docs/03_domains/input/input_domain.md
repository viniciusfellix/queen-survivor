# Domínio — Input

As actions são definidas no **Input Map nativo** do projeto (`project.godot [input]`), não criadas por código. São 9 actions:

| Action | Bindings |
|---|---|
| `move_left` / `move_right` / `move_up` / `move_down` | WASD + setas + analógico esquerdo |
| `aim_left` / `aim_right` / `aim_up` / `aim_down` | analógico direito |
| `dash` | Espaço |

`InputManager` apenas **lê** input (`Input.get_action_strength`, `Input.is_action_just_pressed`) e centraliza movimento e mira; mantém a última direção válida de mira. Prioridade de mira: analógico acima do deadzone, mouse, direção de movimento e última direção válida. A arma usa mira; o visual da Gaia usa movimento horizontal para facing.
