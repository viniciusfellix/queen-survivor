# PR17 - Docs, Encoding e Tech Debt

## Objetivo da PR

Corrigir documentacao stale, consolidar o estado tecnico real do projeto apos as PRs de migracao e regravar os arquivos alterados em UTF-8 valido, sem alterar runtime.

## Arquivos revisados

- `docs/README.md`
- `docs/09_tech_debt.md`
- `docs/migration/CURRENT_SOURCE_OF_TRUTH.md`
- `docs/01_architecture/scene_architecture.md`
- `docs/02_lifecycles/coin_drop_lifecycle.md`
- `docs/02_lifecycles/combat_hitbox_hurtbox_lifecycle.md`
- `docs/03_domains/localization/localization_domain.md`
- `docs/07_debug_audit/README_DEBUG_AUDIT.md`
- busca textual ampla em `docs/`

## Arquivos alterados

- `docs/README.md`
- `docs/09_tech_debt.md`
- `docs/migration/CURRENT_SOURCE_OF_TRUTH.md`
- `docs/01_architecture/scene_architecture.md`
- `docs/02_lifecycles/coin_drop_lifecycle.md`
- `docs/02_lifecycles/combat_hitbox_hurtbox_lifecycle.md`
- `docs/03_domains/localization/localization_domain.md`
- `docs/07_debug_audit/README_DEBUG_AUDIT.md`

## Problemas stale encontrados

- `docs/09_tech_debt.md` ainda tratava a migracao de localizacao como item em andamento e ainda citava `LocalizationManager`.
- `docs/09_tech_debt.md` falava em 6 idiomas, enquanto a documentacao atual do projeto registra 7.
- alguns docs centrais ainda estavam com texto antigo ou encoding ruim em trechos de arquitetura, debug e source of truth.
- havia referencias historicas corretas em docs de migracao, mas elas nao deveriam ser confundidas com estado atual.

## Problemas de encoding corrigidos

Os arquivos alterados foram regravados com texto limpo e UTF-8 valido. Os sintomas corrigidos eram do tipo:

- `DocumentaÃ§Ã£o`
- `tÃ©cnica`
- `Ã¡rvore`
- `refatoraÃ§Ã£o`

Nao houve tentativa de reescrever toda a pasta `docs/`; a correcao foi aplicada apenas aos arquivos centrais tocados nesta PR.

## Decisoes documentais consolidadas

- `RunScene` e a source of truth oficial da run.
- `TestGaiaScene` e legado tecnico temporario.
- `DebugRoot` concentra ferramentas tecnicas/dev-only.
- `DebugOverlay` e `PrototypeToolsPanel` sao ferramentas de desenvolvimento, nao gameplay.
- logs verbosos ficam desligados por padrao.
- `CoinDrop` usa `Area2D`, signals e controle de `_physics_process`.
- o combate atual usa `Area2D`, `CollisionShape2D`, layers/masks e signals.
- `BodyCollision` nao causa dano.
- `DamageResolver` calcula dano e nao detecta colisao.
- a localizacao atual e nativa da Godot via `data/localization/translation.csv`.
- o fallback atual `pt_BR` esta configurado em `project.godot`.

## O que ficou para futura documentacao

- revisar o restante da pasta `docs/` apenas por encoding, caso mais arquivos antigos precisem ser normalizados;
- consolidar um guia unico de build limpa/dev mode quando o preset de desenvolvimento estiver mais formalizado;
- revisar documentos historicos antigos fora de `docs/`, se existirem, para evitar contradicoes com o estado atual.

## Confirmacao de runtime

Esta PR nao altera:

- scripts de gameplay
- cenas `.tscn`
- resources `.tres`
- `project.godot`
- `Main.gd`
- runtime oficial

## Testes manuais necessarios

1. Conferir `git diff --stat`.
2. Confirmar que apenas arquivos de `docs/` foram alterados.
3. Abrir os arquivos Markdown alterados e verificar acentos/encoding.
4. Pesquisar por termos antigos:
   - `LocalizationManager`
   - `TestGaiaScene` como oficial
   - JSON de localization como estado atual
   - polling de moeda como estado atual
   - polling de hitbox/hurtbox como estado atual
   - logs verbosos ligados por padrao
5. Abrir o projeto no Godot.
6. Confirmar que nao ha missing files.
7. Rodar pelo Play principal rapidamente.
8. Confirmar `RunScene`.
9. Confirmar console sem erro novo.
