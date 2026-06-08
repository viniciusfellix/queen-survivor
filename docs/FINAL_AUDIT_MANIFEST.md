# Final Audit Manifest

## Objetivo

Este manifesto consolida o estado atual do projeto `Queen Survivors` ao fim da rodada de migracao arquitetural e prepara o envio de um pacote `.zip` limpo para auditoria externa/manual.

Ele nao altera runtime. Ele documenta:

- o estado tecnico atual
- o que deve entrar no pacote
- o que deve ficar fora
- como verificar o workspace
- como gerar um zip limpo fora do repositorio

## Estado atual do projeto

### Cena oficial atual

- Cena oficial da run: `res://scenes/run/RunScene.tscn`
- Cena legada de referencia: `res://gameplay/test/TestGaiaScene.tscn`

### Sistemas principais implementados

- player Gaia com movimento, mira, dash e dano
- combate modular com `DirectionalAttackHitbox`, `EnemyAttackHitbox` e `HurtboxComponent`
- inimigos Goblin com perseguicao, ataque, morte, XP e drop
- XP direta, level-up e upgrades
- moeda fisica com magnetismo e coleta
- HUD, feedbacks, resultado e save
- localizacao nativa Godot
- ferramentas dev-only e debug sob `DebugRoot`

### Sistemas otimizados/refatorados na rodada

- `RunScene` promovida a source of truth oficial
- `CoinDrop` migrada para `Area2D` + signals + processamento controlado
- combate com foco em `Area2D`, signals e contrato de dano modular
- pooling/lifecycle reforcado para:
  - moeda
  - hitbox temporaria
  - visual temporario do ataque
  - texto flutuante
  - inimigos
- hot paths com menos polling e menos reflexao dinamica
- defaults de debug/dev-only e logs verbosos mais limpos
- documentacao central consolidada

## Sistemas que usam Godot nativo

- localizacao: `tr(key)` + `TranslationServer` + `data/localization/translation.csv`
- input: Input Map nativo
- pausa: `get_tree().paused` + `process_mode = ALWAYS` onde necessario
- combate: `Area2D`, `CollisionShape2D`, layers/masks, signals
- coleta/magnetismo: `Area2D` + signals

## Estado atual de localizacao

- fonte principal versionada: `res://data/localization/translation.csv`
- fallback atual: `pt_BR`
- estado documentado atual: localizacao nativa Godot
- `LocalizationManager` nao faz parte do runtime atual

## Estado atual de debug / dev-only

- `DebugRoot` organiza ferramentas tecnicas
- `DebugOverlay` e dev-only
- `PrototypeToolsPanel` e dev-only
- `RuntimeTreeSnapshot` continua disponivel por fluxo tecnico
- logs verbosos (`COMBAT`, `SPAWN`, `ANIMATION`, etc.) ficam desligados por padrao

## Estado atual de pooling

`PoolManager` ja cobre os principais objetos de alta rotacao:

- inimigos
- moedas
- hitbox temporaria da arma
- visual temporario da arma
- floating combat text

## Pendencias conhecidas para auditoria

- validar manualmente o checklist da PR18
- possiveis docs antigos ainda com encoding ruim fora dos docs centrais
- decidir `dev mode` / `build mode` explicito no futuro
- decidir destino final de `allow_debug_force_finish` em preset/cena futura
- fazer profiling real de horda pesada, nao apenas checklist manual
- avaliar cache de `Shape2D` runtime apenas se profiling justificar
- futuras revisoes maiores em `EnemyBase` e `PlayerController`
- funcionalidades novas continuam fora do escopo desta rodada

## O que deve entrar no zip

Inclua no pacote:

- `project.godot`
- `autoloads/`
- `core/`
- `data/`
- `definitions/`
- `docs/`
- `gameplay/`
- `runtime/`
- `scenes/`
- `ui/`
- `visual/`
- `assets/` necessarios
- arquivos `.gd`
- arquivos `.tscn`
- arquivos `.tres` / `.res`
- arquivos `.uid` necessarios do Godot
- `icon.svg` e imports necessarios se fizerem parte do projeto carregado

### Inclusoes opcionais e intencionais

So inclua se a auditoria externa realmente precisar deles:

- `AUDIT_01_PROJECT_INVENTORY.md`
- `AUDIT_02_ARCHITECTURE_REVIEW.md`
- `AUDIT_03_SYSTEM_CLASSIFICATION.md`
- `AUDIT_04_GODOT_NATIVE_REFACTOR_PLAN.md`
- `AUDIT_05_REUSE_OR_REWRITE_MATRIX.md`
- `AUDIT_06_STEP_BY_STEP_MIGRATION_ROADMAP.md`
- `AUDIT_07_RISKS_AND_DECISIONS.md`
- `TARGET_ARCHITECTURE_GODOT_NATIVE.md`
- `REUSE_DECISION_MATRIX.md`

Esses arquivos podem ser uteis para auditoria manual, mas nao sao obrigatorios para o projeto abrir/rodar.

## O que nao deve entrar no zip

Nao inclua:

- `.git/`
- `.godot/`
- arquivos `.tmp`
- arquivos `.tmp.*`
- caches do editor
- zips antigos
- builds exportadas
- logs locais
- arquivos pessoais do editor
- relatorios temporarios fora do escopo, salvo se forem intencionalmente incluidos

## Verificacoes sugeridas antes de empacotar

### Estado do workspace

```powershell
git status
git diff --stat
git ls-files
```

### Procurar temporarios

```powershell
rg --files -g "*.tmp" -g "*.tmp.*"
```

### Confirmar que `.godot/` nao esta versionado

```powershell
git ls-files | rg "^\.godot/|/\.godot/"
```

## Observacao importante de workspace atual

Se o workspace local ainda tiver arquivos modificados fora do escopo, nao inclua essas mudancas sem revisar.

No momento desta PR, foram observados como modificados localmente:

- `gameplay/spawners/EnemySpawner.tscn`
- `gameplay/test/TestGaiaScene.tscn`

Esses arquivos nao foram alterados por esta PR19 e devem ser tratados separadamente antes de gerar o pacote final.

## Como gerar um zip limpo no PowerShell

### Estrategia recomendada

1. criar uma pasta temporaria fora do repositorio
2. copiar apenas arquivos rastreados pelo Git
3. remover da copia qualquer item que nao deva ir para auditoria
4. compactar a pasta temporaria

### Exemplo de fluxo

```powershell
$ProjectRoot = "C:\Users\acer\Documents\Godot\Projects\queen-survivor"
$StageRoot = Join-Path $env:TEMP "queen-survivor-audit-package"
$ZipPath = Join-Path $env:TEMP "queen-survivors-audit-package.zip"

if (Test-Path $StageRoot) { Remove-Item -Recurse -Force $StageRoot }
if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }

New-Item -ItemType Directory -Path $StageRoot | Out-Null

git -C $ProjectRoot ls-files | ForEach-Object {
    $source = Join-Path $ProjectRoot $_
    $target = Join-Path $StageRoot $_
    $targetDir = Split-Path $target -Parent

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item $source $target -Force
}

Get-ChildItem $StageRoot -Recurse -Force -Include *.tmp,*.tmp.* | Remove-Item -Force
Remove-Item -Recurse -Force (Join-Path $StageRoot ".git") -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $StageRoot ".godot") -ErrorAction SilentlyContinue

Compress-Archive -Path (Join-Path $StageRoot "*") -DestinationPath $ZipPath -Force
```

### Validacao final recomendada

Antes de enviar:

- abrir o zip
- confirmar ausencia de `.git/`
- confirmar ausencia de `.godot/`
- confirmar ausencia de `.tmp`
- confirmar presenca de `project.godot`
- confirmar presenca de `scenes/run/RunScene.tscn`
- confirmar presenca de `autoloads/`, `gameplay/`, `ui/`, `visual/`, `docs/`

## Checklist final antes de enviar

- [ ] `git status` revisado
- [ ] `git diff --stat` revisado
- [ ] `.godot/` fora do pacote
- [ ] `.git/` fora do pacote
- [ ] `.tmp` fora do pacote
- [ ] arquivos modificados fora do escopo resolvidos ou conscientemente excluidos
- [ ] `project.godot` presente
- [ ] `RunScene.tscn` presente
- [ ] docs de migracao presentes
- [ ] checklist da PR18 anexado/presente para QA manual
