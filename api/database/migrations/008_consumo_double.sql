-- Consumo e estimativa numerica, como o double do app e number da API.
-- Nao altera litros, precos ou valores pagos.
ALTER TABLE fichas MODIFY km_litro DOUBLE NOT NULL, MODIFY km_litro_alcool DOUBLE NULL;
