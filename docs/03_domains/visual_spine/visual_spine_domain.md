# Domínio — Visual e Spine

Spine representa estado e não decide gameplay. `SpineAnimationAdapterBase` e `SpineVisualControllerBase` centralizam comportamento comum.

- `GaiaVisualController`: idle/run/death e flash vermelho.
- `GoblinWarriorVisualController`: idle/run/death e flash claro.

Feedback de modulação não substitui animação nem altera dano.
