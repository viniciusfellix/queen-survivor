# Regressão Completa — Módulo 1

## A — Boot e cena

- [ ] Localization/save/input/run carregam.
- [ ] Gaia e câmera são configuradas.
- [ ] Spawner recebe Player/EnemyRoot.
- [ ] Console sem erro/warning.

## B — Movimento, mira e Spine

- [ ] Movimento teclado/controle.
- [ ] Mira mouse/analógico.
- [ ] Ataque aponta pela mira.
- [ ] Facing visual segue movimento.
- [ ] Idle/run/death corretos.

## C — Gaia atacando Goblin

- [ ] Rectangle aparece alinhada.
- [ ] Centro e bordas acertam; fora não acerta.
- [ ] Dano base contra fraqueza é `final=10`.
- [ ] Flash claro aparece.
- [ ] Morto não recebe novo dano.

## D — Goblin atacando Gaia

- [ ] Ataque só ocorre em contato entre áreas.
- [ ] Delay `0.75s` e intervalo `1.0s` respeitados.
- [ ] Raw 6 causa 6 sem defesa.
- [ ] Defesa reduz corretamente.
- [ ] Flash vermelho, floating text e invencibilidade funcionam.
- [ ] Gaia morta não recebe novo dano.

## E — XP, level-up e upgrades

- [ ] Kill concede XP.
- [ ] Três cards abrem com ícone/badge.
- [ ] Player upgrades aplicam.
- [ ] Damage/cooldown/lifetime aplicam.
- [ ] `weapon_attack_area_scale_percent` amplia rectangle.
- [ ] Nome antigo de radius não reaparece.

## F — Moeda, resultado e save

- [ ] Drop/magnetismo/coleta funcionam.
- [ ] Vitória multiplica/bonifica moedas coletadas.
- [ ] Derrota não multiplica.
- [ ] ResultPanel exibe payload.
- [ ] Save persiste e reset técnico funciona.

## G — Encerramento

- [ ] Snapshot sem duplicidades anormais.
- [ ] Busca residual retorna zero.
- [ ] Canais temporários desligados.

## Etapa 2R2-B — Testes regressivos

- [ ] Goblins perseguem Gaia.
- [ ] Goblins se esbarram sem empilhar.
- [ ] Esbarrão não causa dano.
- [ ] Goblins deslizam sem inverter animação.
- [ ] Goblins ainda atacam Gaia por EnemyAttackHitbox.
- [ ] Gaia recebe dano por PlayerHurtbox.
- [ ] Arma da Gaia causa dano por EnemyHurtbox.
- [ ] Knockback da arma ocorre apenas após dano válido.
- [ ] Goblins voltam a perseguir após knockback.
- [ ] Morte de Goblin gera XP/moeda.
- [ ] Upgrades de arma continuam funcionando.
- [ ] Blink da Gaia roda em overlay.
- [ ] Idle da Gaia não congela durante blink.
- [ ] Run da Gaia continua normal.
- [ ] Morte da Gaia interrompe blink.
- [ ] Logs detalhados ficam desligados por padrão.

## Etapa — Pooling, pausa nativa, colisão e plataforma

- [ ] Pooling: inimigos reaparecem reutilizados com estado resetado (HP cheio, sem hits antigos).
- [ ] Pooling: moedas reaparecem reutilizadas com estado limpo.
- [ ] Pausa nativa: level-up congela inimigos enquanto a UI segue, e retoma ao escolher.
- [ ] Colisão: a Gaia não é empurrada/teleportada em aglomerados de inimigos.
- [ ] Localização: trocar locale com `TranslationServer.set_locale` reflete na UI.
- [ ] Input: mover/mirar/dash pelo Input Map (teclado e gamepad).
