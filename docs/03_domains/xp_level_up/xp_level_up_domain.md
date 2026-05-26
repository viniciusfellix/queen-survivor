# Domínio — XP e Level-up

XP é única: alimenta level-up durante a run e é incorporada ao resultado final.

## Progressão atual

A run começa no nível 1 com requisito inicial de 10 XP. Requisito seguinte:

```text
10 + ((nível_atual - 1) × 5)
```

## Opções

`LevelUpOptionService` escolhe upgrades válidos, respeitando `max_stack_in_run`, evitando repetir a oferta imediatamente anterior quando possível e usando fallback quando a pool válida é pequena.

## Pendência

Steps progressivos por stack ainda não foram implementados e exigirão modelagem própria futura.
