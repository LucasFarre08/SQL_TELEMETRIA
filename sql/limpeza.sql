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

UPDATE freio
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));
UPDATE ociosidade
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));
UPDATE seguranca
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(data, '%Y%m'));
UPDATE rpm_amerelo
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));
UPDATE rpm_vermelho
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));
UPDATE velocidade_80km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));
UPDATE velocidade_chuva_60km
SET
    ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'));



