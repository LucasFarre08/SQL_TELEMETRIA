SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

CREATE TABLE IF NOT EXISTS agregado_mensal_ociosidade (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    duracao TIME NOT NULL,
    duracao_int DECIMAL(14,2) DEFAULT 0,
    litros_gasto DECIMAL(14,2) DEFAULT 0,
    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_ociosidade;

CREATE TEMPORARY TABLE tmp_agregado_ociosidade (
    grouping_id VARCHAR(64) NOT NULL,
    ano_mes DATE NOT NULL,
    duracao TIME NOT NULL,
    duracao_int DECIMAL(14,2) DEFAULT 0,
    litros_gasto DECIMAL(14,2) DEFAULT 0,
    PRIMARY KEY (grouping_id, ano_mes)
) ENGINE=InnoDB;

INSERT INTO tmp_agregado_ociosidade (
    grouping_id,
    ano_mes,
    duracao,
    duracao_int,
    litros_gasto
)
SELECT
    REPLACE(REPLACE(TRIM(UPPER(`grouping`)),'.',''),'-','') AS grouping_id,
    DATE_FORMAT(ativado,'%Y-%m-01') + INTERVAL 0 DAY AS ano_mes,
    SEC_TO_TIME(SUM(TIME_TO_SEC(duracao))) AS duracao,
    ROUND(SUM(TIME_TO_SEC(duracao))/3600,2) AS duracao_int,
    ROUND(SUM(IFNULL(combustivel_gasto,0)),2) AS litros_gasto
FROM ociosidade
WHERE ativado IS NOT NULL
  AND TRIM(`grouping`) <> ''
GROUP BY
    REPLACE(REPLACE(TRIM(UPPER(`grouping`)),'.',''),'-',''),
    DATE_FORMAT(ativado,'%Y-%m-01');

UPDATE agregado_mensal_ociosidade a
JOIN tmp_agregado_ociosidade t
ON a.grouping_id = t.grouping_id
AND a.ano_mes = t.ano_mes
SET
    a.duracao = t.duracao,
    a.duracao_int = t.duracao_int,
    a.litros_gasto = t.litros_gasto;

INSERT INTO agregado_mensal_ociosidade (
    grouping_id,
    ano_mes,
    duracao,
    duracao_int,
    litros_gasto
)
SELECT
    t.grouping_id,
    t.ano_mes,
    t.duracao,
    t.duracao_int,
    t.litros_gasto
FROM tmp_agregado_ociosidade t
LEFT JOIN agregado_mensal_ociosidade a
ON a.grouping_id = t.grouping_id
AND a.ano_mes = t.ano_mes
WHERE a.grouping_id IS NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_agregado_ociosidade;

COMMIT;