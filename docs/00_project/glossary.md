# Glossário Oficial

| Termo | Significado |
|---|---|
| Queen | Personagem jogável; atualmente Gaia. |
| Run | Sessão de gameplay iniciada no mapa e encerrada por vitória/derrota. |
| Resource | Arquivo `.tres` editável no Inspector com configuração/balanceamento. |
| Definition | Classe Resource que descreve conteúdo, como `EnemyDefinition`. |
| Runtime | Estado mutável existente apenas durante a execução. |
| BodyCollision | Colisão física de movimento/bloqueio; não causa nem recebe dano. |
| Hitbox | Área ofensiva que envia dano quando detecta hurtbox válida. |
| Hurtbox | Área vulnerável que encaminha dano ao receiver da entidade. |
| CombatShapeDefinition | Geometria configurável compartilhada por hitboxes/hurtboxes. |
| AttackAreaDefinition | Shape semântica ofensiva. |
| HurtboxAreaDefinition | Shape semântica vulnerável. |
| DamagePayload | Pacote de dano com fonte, tipo e componentes. |
| DamageComponentDefinition | Parte tipada do dano, como physical/magical. |
| XP única | XP usada durante a run e persistida no resultado. |
| Coin Drop | Moeda física gerada após morte conforme chance. |
| Stack | Quantidade de seleções de um upgrade durante a run. |
| Event Bus | `GameEvents`, publicação/consumo de sinais entre domínios. |
| Audit Log | Log técnico categorizado pelo `DeveloperAuditLogger`. |
| Snapshot Runtime | Exportação compactada da árvore de nodes em execução. |
| Spine | Camada visual/animação; não decide gameplay. |
| PoolManager | Autoload de object pooling; reaproveita instâncias por cena (inimigos, moedas, hitbox/visual de ataque, texto flutuante) via `spawn`/`despawn`, mantendo inativas fora da árvore. |
| Pooling | Reaproveitar instâncias em vez de `instantiate()`/`queue_free()` no caminho quente, para sustentar milhares de entidades. |
| Pausa nativa | Pausa de gameplay via `get_tree().paused` + `process_mode = ALWAYS`; substitui `is_gameplay_blocked`. |
| ~~is_gameplay_blocked~~ | **Removido.** Checagem de bloqueio por frame; substituída pela pausa nativa (ver ADR 0012). |
| ~~LocalizationManager~~ | **Removido.** Autoload de tradução por JSON próprio; substituído por tradução nativa do Godot (`tr(key)` + CSV, ver ADR 0013). |
