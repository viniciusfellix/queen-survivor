# Arquitetura — Autoloads

| Autoload | Responsabilidade atual |
|---|---|
| `App` | título, versão e log de boot |
| `LocalizationManager` | carregar JSON de idioma e retornar `get_text(key)` |
| `InputManager` | movimento, mira e última direção válida |
| `SaveManager` | carregar/criar save, aplicar resultado e persistir JSON |
| `GameEvents` | Event Bus de gameplay, UI e persistência |
| `DeveloperAuditLogger` | log técnico por canais e buffer de auditoria |

## Regras

- Autoload não deve conhecer a árvore interna de uma cena específica quando uma referência/evento resolve a integração.
- `GameEvents` publica ocorrências; não executa lógica de domínio.
- O sistema atual de localização é funcional, mas sua possível migração para tradução nativa Godot continua pendente.
- O save atual é JSON; proteção contra edição externa ainda é futura.
