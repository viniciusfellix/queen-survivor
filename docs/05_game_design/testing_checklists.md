# Checklists de Teste

## Testar inimigo

- O goblin aparece?
- O goblin corre até a Gaia?
- O goblin toca `Run`?
- Quando morre, toca `Die`?
- O goblin causa dano ao encostar?
- O dano respeita cooldown?
- O goblin dá XP ao morrer?
- O goblin dropa moeda conforme chance?

## Testar arma da Gaia

- Ataque nasce na direção do mouse?
- Gaia não vira pelo mouse?
- Hitbox aparece no lugar esperado?
- Goblin recebe dano?
- Dano físico e mágico aparecem no log?
- Fraquezas aplicam bônus?
- Resistências reduzem dano?
- Cooldown muda com upgrade?

## Testar level-up

- XP sobe ao matar inimigo?
- Painel aparece ao subir nível?
- A run pausa?
- 3 opções aparecem?
- Clique aplica upgrade?
- Painel fecha?
- Run continua?

## Testar moeda

- Moeda aparece no chão?
- Moeda não entra direto no contador?
- Magnetismo puxa a moeda?
- Coleta incrementa Run Coins?
- Moeda não coletada permanece fora do total?

## Testar timer, vitória, derrota e resultado

### Timer

- O tempo da run aparece no debug?
- O tempo restante diminui?
- A duração vem do `MapDefinition`?
- Ao mudar `duration_seconds`, o tempo da run muda?

### Vitória

- A run termina quando o timer chega ao limite?
- O resultado aparece como vitória?
- O gameplay pausa?
- O dinheiro final usa multiplicador?
- O bônus de vitória entra depois do multiplicador?

### Derrota

- A run termina quando Gaia morre?
- O resultado aparece como derrota?
- A causa da morte aparece?
- O dinheiro final é igual às moedas coletadas?
- O multiplicador não é aplicado na derrota?

### Moeda não coletada

- Uma moeda deixada no chão fica fora do total?
- O resultado usa apenas `run_coins_collected`?

### XP e estatísticas

- XP obtida aparece no resultado?
- Inimigos derrotados aparecem?
- Nível alcançado aparece?
- Dano causado aparece?
- Dano recebido aparece?
