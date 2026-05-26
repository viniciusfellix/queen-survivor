# Debug e Auditoria — Manual de Testes

## Objetivo

Testar módulos específicos e encontrar problemas estruturais sem manter logs excessivos nas runs normais.

## Painel do Protótipo

```text
F3: mostrar/ocultar ferramentas
F4: exportar árvore runtime
```

Permite forçar vitória, forçar derrota, resetar progressão e consultar run/save. Ações forçadas percorrem o fluxo real e podem persistir resultado.

## Visible Collision Shapes

Use `Debug > Visible Collision Shapes` para investigar combate. Confira ataque retangular Gaia, hurtbox Goblin, ataque Goblin e PlayerHurtbox.

## DeveloperAuditLogger

| Canal | Uso |
|---|---|
| `LIFECYCLE` | boot/resultado |
| `SCENE` | montagem da cena |
| `SPAWN` | inimigos/moedas |
| `COMBAT` | hitboxes/dano/morte |
| `ANIMATION` | Spine/flashes |
| `UPGRADE` | level-up/aplicação |
| `SAVE` | persistência |
| `UI` | painéis/feedback |
| `SIGNAL` | eventos investigados |
| `AUDIT` | operações técnicas |

Ative canais detalhados somente durante o teste correspondente e desligue-os após aprovação.

## Relato de bug ideal

Inclua cenário, resource alterado, canais ativos, logs relevantes, print/relato das collision shapes e comparação entre esperado e obtido.
