-- =========================================================
-- LIMPEZA TELEMETRIA (versão ajustada)
-- - sem transação única: cada UPDATE faz commit sozinho
-- - UPDATEs só tocam linhas que realmente mudam (menos locks)
-- - timeout de lock maior na sessão
-- =========================================================

SET SESSION autocommit = 1;
SET SESSION innodb_lock_wait_timeout = 300;
SET SQL_SAFE_UPDATES = 0;


-- =========================================================
-- VIAGENS / OCIOSIDADE: valores fora do limite viram 0
-- =========================================================

UPDATE viagens
SET
    quilometragem = CASE
        WHEN quilometragem > 1000 OR quilometragem < 0 THEN 0
        ELSE quilometragem
    END,
    litros_consumidos = CASE
        WHEN litros_consumidos > 1000 OR litros_consumidos < 0 THEN 0
        ELSE litros_consumidos
    END
WHERE quilometragem > 1000 OR quilometragem < 0
   OR litros_consumidos > 1000 OR litros_consumidos < 0;

UPDATE ociosidade
SET combustivel_gasto = 0
WHERE combustivel_gasto > 1000 OR combustivel_gasto < 0;


-- =========================================================
-- REMOVE KICKDOWN SEM DATA
-- =========================================================

DELETE FROM kickdown
WHERE ativado IS NULL;


-- =========================================================
-- ano_mes / grouping_ano_mes (banco atual)
-- =========================================================

UPDATE kickdown
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE freio
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE ociosidade
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE seguranca
SET ano_mes = DATE_FORMAT(data, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(data, '%Y%m'))
WHERE data IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(data, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(data, '%Y%m'))));

UPDATE rpm_amarelo
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE rpm_vermelho
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE velocidade_80km
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));

UPDATE velocidade_chuva_60km
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND (NOT (ano_mes <=> DATE_FORMAT(ativado, '%Y%m'))
    OR NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))));


-- =========================================================
-- AGREGADOS MENSAIS (formato GROUPING202609, sem "_")
-- =========================================================

UPDATE agregado_mensal
SET grouping_ano_mes = CONCAT(grouping_id, DATE_FORMAT(ano_mes, '%Y%m'))
WHERE grouping_id IS NOT NULL
  AND ano_mes IS NOT NULL
  AND NOT (grouping_ano_mes <=> CONCAT(grouping_id, DATE_FORMAT(ano_mes, '%Y%m')));

UPDATE agregado_mensal_ociosidade
SET grouping_ano_mes = CONCAT(grouping_id, DATE_FORMAT(ano_mes, '%Y%m'))
WHERE grouping_id IS NOT NULL
  AND ano_mes IS NOT NULL
  AND NOT (grouping_ano_mes <=> CONCAT(grouping_id, DATE_FORMAT(ano_mes, '%Y%m')));


-- =========================================================
-- CONSIGAZ
-- =========================================================

USE telemetria_consigaz;

UPDATE parado_acelerando
SET grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m'))
WHERE ativado IS NOT NULL
  AND NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')));


-- =========================================================
-- SOROCABA
-- Normaliza o grouping ANTES de montar grouping_ano_mes,
-- senão o campo concatenado fica com o grouping sujo.
-- Um único UPDATE por tabela (tira "-" inicial e dígitos iniciais).
-- =========================================================

USE telemetria_sorocaba;

UPDATE viagens
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE kickdown
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE velocidade_via_10
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE ociosidade
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE freio
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE rpm_amarelo
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE rpm_vermelho
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE seguranca
SET `grouping` = REGEXP_REPLACE(TRIM(LEADING '-' FROM `grouping`), '^[0-9]+', '')
WHERE `grouping` REGEXP '^[-0-9]';

UPDATE velocidade_via_10
SET grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(inicio, '%Y%m'))
WHERE inicio IS NOT NULL
  AND NOT (grouping_ano_mes <=> CONCAT(`grouping`, DATE_FORMAT(inicio, '%Y%m')));


-- =========================================================
-- WEST
-- =========================================================

USE telemetria_west;

UPDATE kickdown
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE freio
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE ociosidade
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE seguranca
SET ano_mes = DATE_FORMAT(data, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(data, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(data, '%Y%m'), '_S', CEIL(DAY(data) / 7))
WHERE data IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(data, '%Y%m'), '_S', CEIL(DAY(data) / 7)));

UPDATE rpm_amarelo
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE rpm_vermelho
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE velocidade_80km
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));

UPDATE velocidade_chuva_60km
SET ano_mes = DATE_FORMAT(ativado, '%Y%m'),
    grouping_ano_mes = CONCAT(`grouping`, DATE_FORMAT(ativado, '%Y%m')),
    grouping_semana_ano_mes = CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7))
WHERE ativado IS NOT NULL
  AND NOT (grouping_semana_ano_mes <=> CONCAT(`grouping`, '_', DATE_FORMAT(ativado, '%Y%m'), '_S', CEIL(DAY(ativado) / 7)));
