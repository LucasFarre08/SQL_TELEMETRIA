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

ALTER TABLE kickdown
ADD COLUMN ano_mes VARCHAR(7);
UPDATE kickdown
SET ano_mes = DATE_FORMAT(ativado, '%Y%m');
ALTER TABLE kickdown
ADD COLUMN grouping_ano_mes VARCHAR(255);
UPDATE kickdown
SET grouping_ano_mes = CONCAT(grouping_id, ano_mes);


DELETE FROM kickdown
WHERE ativado is NULL;
