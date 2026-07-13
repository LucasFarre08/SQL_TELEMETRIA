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
