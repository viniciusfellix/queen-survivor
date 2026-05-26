# Domínio — Drops e Moedas

`DropController` reage a `enemy_died` e cria `CoinDrop` conforme chance do inimigo. O drop físico utiliza `CoinDropDefinition` para magnetismo/coleta.

## Regras

- matar não concede moeda automaticamente;
- a moeda precisa ser coletada;
- moeda abandonada é perdida;
- vitória aplica multiplicador do mapa apenas às moedas coletadas;
- derrota entrega moedas coletadas sem multiplicador.
