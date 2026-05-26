# ADR 0009 — Auditoria Estrutural Antes de Encerrar Módulos

## Decisão

Todo módulo técnico deve terminar com revisão estrutural, comentários, regressão e documentação.

## Processo obrigatório

1. revisar scenes/scripts/resources alterados;
2. remover nodes, funções, sinais e arquivos sem uso;
3. extrair helpers/bases quando houver redundância real;
4. comentar funções relevantes;
5. executar testes regressivos;
6. atualizar documentos e ADRs;
7. registrar pendências e atualizar o Chat Core.

## Motivo

O protótipo funcional revelou resíduos e duplicidades que não impediam execução, mas comprometiam manutenção. Qualidade estrutural passa a ser requisito de conclusão.
