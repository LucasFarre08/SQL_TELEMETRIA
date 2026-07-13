SET SQL_SAFE_UPDATES = 0;

UPDATE viagens
SET quilometragem = 0
WHERE quilometragem > 1000;

UPDATE viagens
SET quilometragem = 0
WHERE quilometragem < 0;

UPDATE viagens
SET litros_consumidos = 0
WHERE litros_consumidos > 1000;

UPDATE viagens
SET litros_consumidos = 0
WHERE litros_consumidos < 0;



DELETE FROM kickdown
WHERE ativado is NULL;

UPDATE kickdown
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));

ALTER TABLE kickdown
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE kickdown
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE freio
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE freio
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE ociosidade
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE ociosidade
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE embreagem
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE embreagem
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE rpm_amarelo
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE rpm_amarelo
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE rpm_vermelho
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE rpm_vermelho
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE seguranca
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE seguranca
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE velocidade_80km
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE velocidade_80km
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE velocidade_chuva_60km
ADD COLUMN ano_mes VARCHAR(6);

ALTER TABLE velocidade_chuva_60km
ADD COLUMN grouping_ano_mes VARCHAR(255);

ALTER TABLE agregado_mensal
ADD COLUMN grouping_ano_mes VARCHAR(255);


