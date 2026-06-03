### Knockback por arma

`WeaponDefinition` pode configurar knockback pós-hit:

- `hit_knockback_enabled`;
- `hit_knockback_pixels`;
- `hit_knockback_duration_seconds`.

O knockback é repassado para `DirectionalAttackHitbox`, que só solicita o efeito depois que o receiver confirma dano válido.

O receiver, como `EnemyBase`, decide como aplicar o impulso recebido.

O knockback não faz parte do cálculo de dano e não altera `DamagePayload`.
