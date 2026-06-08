# Lifecycle — Boot da Aplicação

```text
Autoloads inicializam
→ DeveloperAuditLogger prepara canais
→ GameEvents prepara o barramento
→ PoolManager prepara as filas de pool
→ SaveManager carrega/cria save
→ InputManager assegura input
→ App define o locale (TranslationServer.set_locale("pt_BR"))
→ Main instancia RunScene
→ RunScene instancia Gaia e configura câmera/spawners
→ RunController mantém RunState ativo
```

A ordem dos autoloads em `project.godot` é: DeveloperAuditLogger, GameEvents, PoolManager, SaveManager, InputManager, App.

A localização é nativa do Godot (CSV em `data/localization/translation.csv`, `tr()` / `TranslationServer`). Não há mais autoload `LocalizationManager`; o `App` define o idioma no boot via `TranslationServer.set_locale("pt_BR")`.

## Logs mínimos esperados

```text
[DEV][LIFECYCLE] [DeveloperAuditLogger] DeveloperAuditLogger inicializado.
[DEV][SAVE] [SaveManager] Save carregado.
[DEV][LIFECYCLE] [InputManager] Input inicializado.
[DEV][LIFECYCLE] [App] Boot iniciado: Queen Survivors v0.1.0-module-1
[DEV][LIFECYCLE] [RunController] Run iniciada. map=map_test_arena_10min duration=600.0
[DEV][SCENE] [RunScene] Player instanciado: PlayerGaia
[DEV][SCENE] [RunScene] Spawners configurados: 1
[DEV][SCENE] [Main] Cena inicial carregada: res://scenes/run/RunScene.tscn
```
