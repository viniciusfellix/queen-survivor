# Arquitetura — Autoloads

| Autoload | Responsabilidade atual |
|---|---|
| `App` | título, versão, log de boot e `TranslationServer.set_locale("pt_BR")` |
| `InputManager` | lê input (movimento, mira e última direção válida); as actions ficam no Input Map do projeto |
| `PoolManager` | pool central de objetos: filas agrupadas por cena, instâncias inativas fora da árvore; `spawn`/`despawn`/`prewarm`/`clear_all`/`get_scene` |
| `SaveManager` | carregar/criar save, aplicar resultado e persistir JSON |
| `GameEvents` | Event Bus de gameplay, UI e persistência |
| `DeveloperAuditLogger` | log técnico por canais e buffer de auditoria |

## Regras

- Autoload não deve conhecer a árvore interna de uma cena específica quando uma referência/evento resolve a integração.
- `GameEvents` publica ocorrências; não executa lógica de domínio.
- A localização migrou para tradução nativa do Godot: `data/localization/translation.csv` registrado em `project.godot [internationalization]` (`locale/fallback="pt_BR"`, 7 idiomas: pt_BR, en, es, zh, ja, ko, ru). Use `tr(key)` no código e `TranslationServer.set_locale(...)` para trocar idioma. O antigo `LocalizationManager` foi removido.
- `PoolManager` guarda instâncias inativas fora da árvore (não processam nem colidem) e cacheia o `load()` por cena via `get_scene`. Nós poolados podem expor os hooks `_on_pool_acquire()` (reset ao reusar) e `_on_pool_release()`.
- O save atual é JSON; proteção contra edição externa ainda é futura.
