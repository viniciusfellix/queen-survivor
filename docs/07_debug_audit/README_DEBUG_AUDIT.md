# Debug e Auditoria - Manual Rapido

## Objetivo

Usar ferramentas tecnicas para QA e investigacao sem tratar debug como parte do gameplay.

## Ferramentas atuais

- `DebugOverlay`
- `DebugEnemyLinkDrawer`
- `PrototypeToolsPanel`
- `RuntimeTreeSnapshot`
- `DeveloperAuditLogger`

Esses elementos vivem sob `DebugRoot` na `RunScene`.

## Atalhos de desenvolvimento

```text
F3: mostrar/ocultar PrototypeToolsPanel
F4: exportar runtime tree snapshot
```

## Estado atual dos defaults

- `DebugOverlay` nasce desligado por padrao.
- `PrototypeToolsPanel` continua disponivel em desenvolvimento, mas nao aparece aberto no start.
- Canais verbosos do `DeveloperAuditLogger` nao ficam ligados por padrao.
- Debug draw opcional de combate, inimigo e moeda deve permanecer desligado por padrao.

## Visible Collision Shapes

Use `Debug > Visible Collision Shapes` no editor para investigar:

- ataque retangular da Gaia
- hurtbox do Goblin
- ataque do Goblin
- PlayerHurtbox

## Canais do DeveloperAuditLogger

| Canal | Uso |
|---|---|
| `LIFECYCLE` | boot, fechamento, resultado |
| `SCENE` | montagem de cena |
| `SPAWN` | inimigos, moedas, drops |
| `COMBAT` | hitboxes, dano, morte |
| `ANIMATION` | Spine, flashes, visuais |
| `UPGRADE` | level-up e aplicacao |
| `SAVE` | persistencia |
| `UI` | paineis e feedback |
| `SIGNAL` | investigacao de eventos |
| `AUDIT` | operacoes tecnicas |

Ative canais detalhados apenas durante o teste correspondente e desligue depois.
