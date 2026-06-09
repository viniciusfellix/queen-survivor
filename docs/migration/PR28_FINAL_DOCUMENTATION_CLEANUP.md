# PR28 Final Documentation Cleanup

## Objetivo

Consolidar a documentacao final do projeto apos as PRs 1-27, corrigindo termos stale, links principais, encoding residual e removendo artefatos documentais desnecessarios.

## O que esta PR fez

- criou docs consolidados por dominio
- atualizou o indice principal em `docs/README.md`
- marcou `docs/migration/` como historico
- consolidou `RunScene` como source of truth documental
- registrou o status final `READY_WITH_FOLLOW_UPS`
- removeu `docs/migration.zip`

## Informacoes consolidadas

- cena oficial: `res://scenes/run/RunScene.tscn`
- stress scene: `res://scenes/test/StressRunScene.tscn`
- `TestGaiaScene` como legado tecnico
- localizacao nativa Godot como estado atual
- Damage Model V2 como regra oficial
- stress result oficial:
  - 90 vivos: ~60 FPS
  - 120 vivos: ~50 FPS
  - 140 vivos: ~40 FPS
  - 180 vivos: ~30 FPS

## Termos antigos corrigidos

- `RunScene` como cena futura/paralela
- `TestGaiaScene` como cena oficial
- `LocalizationManager` como sistema atual
- polling continuo de moeda/hitbox como estado atual
- logs verbosos como padrao
- `docs/migration.zip` como artefato ainda esperado

## Runtime

Nenhum arquivo de runtime foi alterado nesta PR.
