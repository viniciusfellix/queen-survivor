# Lifecycle — Boot da Aplicação

```text
Autoloads inicializam
→ DeveloperAuditLogger prepara canais
→ LocalizationManager carrega idioma
→ SaveManager carrega/cria save
→ InputManager assegura input
→ Main instancia TestGaiaScene
→ TestGaiaScene instancia Gaia e configura câmera/spawners
→ RunController mantém RunState ativo
```

## Logs mínimos esperados

```text
[DEV][LIFECYCLE] [DeveloperAuditLogger] DeveloperAuditLogger inicializado.
[DEV][LIFECYCLE] [LocalizationManager] Idioma carregado: pt_br
[DEV][SAVE] [SaveManager] Save carregado.
[DEV][LIFECYCLE] [InputManager] Input inicializado.
[DEV][LIFECYCLE] [App] Boot iniciado: Queen Survivors v0.1.0-module-1
[DEV][LIFECYCLE] [RunController] Run iniciada. map=map_test_arena_10min duration=600.0
[DEV][SCENE] [TestGaiaScene] Player instanciado: PlayerGaia
[DEV][SCENE] [TestGaiaScene] Spawners configurados: 1
[DEV][SCENE] [Main] Cena inicial carregada: res://gameplay/test/TestGaiaScene.tscn
```
