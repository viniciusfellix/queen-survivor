# Criar Novo Upgrade

## Processo

1. Confirme que o tipo é suportado em `UpgradeTypes.gd`.
2. Crie `upgrade_<efeito>.tres`.
3. Configure ID, localization, ícone, `upgrade_type`, valores, stacks e badge.
4. Inclua na pool apropriada.
5. Teste aparição, seleção, efeito e limites.

## ID versus upgrade type

```text
id: upgrade_weapon_attack_area_scale_percent
upgrade_type: weapon_attack_area_scale_percent
```

O type não recebe o prefixo `upgrade_`.

## Valores

- `value_int`: dano +1, HP +10, cura +20.
- `value_float`: velocidade +8%, cooldown -1.5%, área +10%.
