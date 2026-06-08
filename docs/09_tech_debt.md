# Tech Debt - Estado Atual

Este arquivo lista tech debts reais que continuam relevantes depois das PRs de migracao, pooling e hot path cleanup. Ele nao repete itens ja concluídos.

## Confirmacoes do estado atual

- `RunScene` e a cena oficial atual da run.
- `TestGaiaScene` e legado tecnico temporario.
- A localizacao ja usa o sistema nativo do Godot via `data/localization/translation.csv`.
- O fallback atual `pt_BR` esta configurado em `project.godot`.
- `LocalizationManager` nao faz mais parte do runtime atual.
- `CoinDrop` ja usa `Area2D`, signals e processamento de fisica controlado.
- O combate atual usa `Area2D`, `CollisionShape2D`, layers/masks e signals em hitboxes/hurtboxes.
- `BodyCollision` nao causa dano.
- `DamageResolver` calcula dano; nao detecta colisao.
- Entidades temporarias e inimigos relevantes ja usam `PoolManager`.

## Debitos tecnicos ainda ativos

### Alta prioridade

- [ ] **RunHud ainda mistura polling e debug data**  
  `ui/hud/RunHud.gd` ainda faz refresh periodico completo e consulta `get_debug_data()` de player/run controller. O ideal e migrar a HUD para atualizacao mais granular por evento e deixar `get_debug_data()` restrito ao debug.

- [ ] **DebugOverlay ainda reconstrói texto tecnico periodicamente**  
  `ui/debug/DebugOverlay.gd` continua montando texto agregado e buscando dados tecnicos em refresh recorrente. Como e dev-only, o impacto e limitado, mas ainda ha espaco para reduzir custo e acoplamento.

- [ ] **Logs ainda formatam strings antes do gate do canal em varios pontos**  
  Em caminhos como combate, spawn e animacao, varios scripts ainda montam mensagem e metadata antes de `DeveloperAuditLogger` descartar o canal desligado. Vale encapsular melhor isso nos hot paths.

### Media prioridade

- [ ] **RunHud ainda depende de contrato dinamico de debug**  
  A HUD principal ainda consulta `get_debug_data()` em vez de consumir apenas os payloads que ja chegam por `GameEvents`.

- [ ] **DebugOverlay ainda sincroniza configuracao do link drawer por assinatura textual**  
  O comportamento atual esta melhor que polling bruto continuo, mas ainda pode ser simplificado com contrato mais direto para configuracoes dev-only.

- [ ] **Resolucoes duplicadas de player/target/group lookup ainda existem em multiplos scripts**  
  Existem helpers parecidos de busca por grupo em `EnemyBase`, `CoinDrop`, `EnemySpawner`, camera e outros pontos. Um helper unico de consulta de cena reduziria duplicacao.

- [ ] **Visual controllers ainda usam reflexao dinamica para falar com adapters Spine**  
  Isso esta aceitavel hoje por compatibilidade, mas ainda existe oportunidade de explicitar contratos e reduzir `has_method()/call()`.

- [ ] **Save continua em JSON manual**  
  O sistema atual funciona para prototipo, mas ainda nao migrou para serializacao nativa por `ResourceSaver/ResourceLoader`.

### Baixa prioridade

- [ ] **PrototypeToolsPanel e RuntimeTreeSnapshot seguem bem focados em desenvolvimento**  
  O fluxo e util, mas ainda pode ganhar preset ou modo explicito de build/dev no futuro para separar melhor ambiente de QA e build limpa.

- [ ] **Alguns defaults de debug permanecem configuraveis por script/cena, nao por modo global**  
  Isso esta sob controle hoje, mas um sistema simples de `dev mode` ainda seria uma consolidacao util.

- [ ] **Documentacao historica de PRs antigas continua mencionando estados passados**  
  Isso e aceitavel como historico, mas deve continuar sendo lido como contexto de evolucao, nao como estado atual do projeto.

## Pendencias a verificar manualmente

- Confirmar no editor Godot qual das attack areas duplicadas da Gaia deve permanecer como oficial.
- Confirmar se ha mais algum documento antigo fora de `docs/` usado por equipe/QA com referencias a `LocalizationManager`, `TestGaiaScene` como oficial ou polling antigo de moeda/combate.
