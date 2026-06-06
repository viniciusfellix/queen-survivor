# Domínio — Visual e Spine

Spine representa estado e não decide gameplay. `SpineAnimationAdapterBase` e `SpineVisualControllerBase` centralizam comportamento comum.

- `GaiaVisualController`: idle/run/death e flash vermelho.
- `GoblinWarriorVisualController`: idle/run/death e flash claro.

Feedback de modulação não substitui animação nem altera dano.

`GaiaAttackVisualController` (visual do ataque da Gaia) é poolizado via `PoolManager`: faz `despawn` ao fim do `lifetime` e `_on_pool_acquire()` reseta alpha/elapsed a cada reúso.
